#
# Copyright (C) 2012 UNINETT
#
# This file is part of Network Administration Visualized (NAV).
#
# NAV is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.  You should have received a copy of the GNU General Public License
# along with NAV. If not, see <http://www.gnu.org/licenses/>.
#
"""Topology evaluation functions for event processing"""
import socket
import datetime

import networkx
from nav.models.manage import SwPortVlan, Netbox, Prefix, Arp, Cam

import logging
_logger = logging.getLogger(__name__)

def is_netbox_reachable(netbox):
    """Returns True if netbox appears to be reachable through the known
    topology.

    """
    target_path = get_path_to_netbox(netbox)
    nav = NAVServer.make_for(netbox.ip)
    nav_path = get_path_to_netbox(nav) if nav else True
    _logger.debug("reachability paths, target_path=%(target_path)r, "
                  "nav_path=%(nav_path)r", locals())
    return bool(target_path and nav_path)

def get_path_to_netbox(netbox):
    """Returns a likely path from netbox to its apparent gateway/router.

    If any switches on the path, or the router itself is down,
    no current path exists and a False value is returned. However,
    if there is insufficient information for NAV to find a likely path,
    a True value is returned.

    """
    prefix = netbox.get_prefix()
    router_port = prefix.get_router_ports()[0]
    router = router_port.interface.netbox
    _logger.debug("reachability check for %s on %s (router: %s)",
                  netbox, prefix, router)

    graph = get_graph_for_vlan(prefix.vlan)
    try:
        netbox.add_to_graph(graph)
    except AttributeError:
        pass
    strip_down_nodes_from_graph(graph, keep=netbox)

    if netbox not in graph or router not in graph:
        if router.up == router.UP_UP:
            _logger.warning("%(netbox)s topology problem: router %(router)s "
                            "is up, but not in VLAN graph for %(prefix)r. "
                            "Defaulting to 'reachable' status.", locals())
            return True
        _logger.debug("%s not reachable, router or box not in graph: %r",
                      netbox, graph.edges())
        return False

    path = networkx.shortest_path(graph, netbox, router)
    _logger.debug("path to %s: %r", netbox, path)
    return path

def get_graph_for_vlan(vlan):
    """Builds a simple topology graph of the active netboxes in vlan.

    Any netbox that seems to be down at the moment will not be included in
    the graph.

    :returns: A networkx.Graph object.

    """
    swpvlan = SwPortVlan.objects.filter(vlan=vlan).select_related(
        'interface', 'interface__netbox',  'interface__to_netbox')
    graph = networkx.Graph(name='graph for vlan %s' % vlan)
    for swp in swpvlan:
       source = swp.interface.netbox
       target = swp.interface.to_netbox
       if target:
           graph.add_edge(source,target)
    return graph

def strip_down_nodes_from_graph(graph, keep=None):
    """Strips all nodes (netboxes) from graph that are currently down.

    :param keep: A node to keep regardless of its current status.

    """
    removable = set(node for node in graph.nodes_iter()
                    if node.up != node.UP_UP and node != keep)
    graph.remove_nodes_from(removable)
    return len(removable)

###
### Functions for locating the NAV server itself
###

class NAVServer(object):
    """A simple mockup of a Netbox representing the NAV server itself"""
    UP_UP = Netbox.UP_UP

    @classmethod
    def make_for(cls, dest):
        """Creates a NAVServer instance with the source IP address of the
        local host used for routing traffic to dest.

        :param dest: An IP address
        """

        ipaddr = get_source_address_for(dest)
        if ipaddr:
            return cls(ipaddr)

    def __init__(self, ip):
        self.sysname = "NAV"
        self.ip = ip
        self.up = Netbox.UP_UP

    def get_prefix(self):
        matches = Prefix.objects.contains_ip(self.ip)
        if matches:
            return matches[0]

    def add_to_graph(self, graph):
        for switch in self.get_switches_from_cam():
            graph.add_edge(self, switch)

    def get_switches_from_cam(self):
        mac = self.get_mac_from_arp()
        if mac:
            records = Cam.objects.filter(
                mac=mac,
                end_time__gte=datetime.datetime.max
            ).select_related('netbox')
            return list(set(cam.netbox for cam in records))
        else:
            return []

    def get_mac_from_arp(self):
        arp = Arp.objects.extra(
            where=['ip = %s'],
            params=[self.ip]
        ).filter(end_time__gte=datetime.datetime.max)
        if arp:
            return arp[0].mac

    def __repr__(self):
        return "{self.__class__.__name__}({self.ip!r})".format(self=self)

def get_source_address_for(dest):
    """Gets the source IP address used by this host when attempting to
    contact the destination host.

    :param dest: An IP address string.
    :return: And IP address string, or None if no address was found.

    """
    family, sockaddr = _get_target_dgram_addr(dest)
    sock = socket.socket(family, socket.SOCK_DGRAM)
    try:
        sock.connect(sockaddr)
    except socket.error, err:
        _logger.warning("Error when getting NAV's source address for "
                        "connecting to %(dest)s: %(err)s", locals())
        return
    addrinfo = sock.getsockname()
    sock.close()
    return addrinfo[0]

def _get_target_dgram_addr(target):
    """Returns a (family, sockaddr) tuple for the target address for
    a SOCK_DGRAM socket type.

    """
    for (family, socktype,
         _proto, _canonname,
         sockaddr) in socket.getaddrinfo(target, 1):
        if socktype == socket.SOCK_DGRAM:
            return family, sockaddr