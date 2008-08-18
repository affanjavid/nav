# -*- coding: ISO8859-1 -*-
# Copyright 2008 UNINETT AS
#
# This file is part of Network Administration Visualized (NAV)
#
# NAV is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# NAV is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NAV; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# Author: Thomas Adamcik <thomas.adamcik@uninett.no>
#

__copyright__ = "Copyright 2008 UNINETT AS"
__license__ = "GPL"
__author__ = "Thomas Adamcik (thomas.adamcik@uninett.no)"
__id__ = "$Id$"

from django.template.loader import get_template
from django.template import Context

from nav.models.manage import Location, Room, Netbox, Module
from nav.models.service import Service

class QuickSelect:
    def __init__(self, **kwargs):
        self.button = kwargs.pop('button', 'Add %s')

        self.location = kwargs.pop('location', True)
        self.room     = kwargs.pop('room',     True)
        self.netbox   = kwargs.pop('netbox',   True)
        self.service  = kwargs.pop('service',  False)
        self.module   = kwargs.pop('module',   False)

        self.location_label = kwargs.pop('location_label', '%(id)s (%(description)s)')
        self.room_label     = kwargs.pop('room_label',     '%(id)s (%(description)s)')
        self.netbox_label   = kwargs.pop('netbox_label',   '%(sysname)s')
        self.service_label  = kwargs.pop('service_label',  '%(handler)s')
        self.module_label   = kwargs.pop('module_label',   '%(module_number)d')

        self.location_multi = kwargs.pop('location_multiple', True)
        self.room_multi     = kwargs.pop('room_multiple',     True)
        self.netbox_multi   = kwargs.pop('netbox_multiple',   True)
        self.service_multi  = kwargs.pop('service_multiple',  True)
        self.module_multi   = kwargs.pop('module_multiple',   True)

        for key in kwargs.keys():
            raise TypeError('__init__() got an unexpected keyword argument %s' % key)

        # Quick hack to add the serial to our values.
        netbox_value_args = [f.attname for f in Netbox._meta.fields]
        netbox_value_args.append('device__serial')
        self.netbox_set = Netbox.objects.order_by('sysname').values(*netbox_value_args)

        # Rest of the queryset we need
        self.location_set = Location.objects.order_by(('id')).values()
        self.service_set = Service.objects.order_by('handler').values()
        self.module_set = Module.objects.order_by('module_number').values()
        self.room_set = Room.objects.order_by('id').values()

        self.output = []

    def handle_post(self, request):
        # Django requests has post and get data stored in an attribute called
        # REQUEST, while mod_python request stores it in form.
        #
        # This little if/else makes sure we can use both.
        if hasattr(request, 'REQUEST'):
            form = request.POST
        else:
            form = request.form

        result = {
            'location': [],
            'service': [],
            'netbox': [],
            'module': [],
            'room': [],
        }

        for field in result.keys():
            submit = 'submit_%s' % field
            key = field

            if field == 'location':
                # Hack to work around noscript XSS protection that triggers on
                # location
                key = key.replace('location', 'loc')
                submit = submit.replace('location', 'loc')

            if getattr(self, field):
                if submit in form and key in form:
                    result[field] = form.getlist(key)
                elif 'add_%s' % key in form:
                    result[field] = form.getlist('add_%s' % key)
                elif 'view_%s' % key in form:
                    result[field] = form.getlist('view_%s' % key)
                elif key != field:
                    # Extra check that allows add_loc in addtion to
                    # add_location
                    if 'add_%s' % field in form:
                         result[field] = form.getlist('add_%s' % field)
                    elif 'view_%s' % field in form:
                         result[field] = form.getlist('view_%s' % field)

                if not getattr(self, '%s_multi' % field):
                    # Limit to first element if multi is not set.
                    result[field] = result[field][:1]

        return result

    def __str__(self):
        if not self.output:
            output = []
            location_name = {}
            room_name = {}
            netbox_name = {}

            if self.location:
                locations = {'': []}
                for location in self.location_set:
                    location_name[location['id']] = self.location_label % location
                    locations[''].append((location['id'], location_name[location['id']]))

                # use loc instead of location to avoid noscript XSS protection
                output.append({
                        'label': 'Location',
                        'button': self.button % 'location',
                        'multi': self.location_multi,
                        'name': 'loc',
                        'collapse': True,
                        'objects': sorted(locations.iteritems()),
                    })

            if self.room:
                rooms = {}
                for room in self.room_set:
                    location = location_name.get(room['location_id'])
                    room_name[room['id']] = self.room_label % room
                    if location in rooms:
                        rooms[location].append((room['id'], room_name[room['id']]))
                    else:
                        rooms[location] = [(room['id'], room_name[room['id']])]

                output.append({
                        'label': 'Room',
                        'button': self.button % 'room',
                        'multi': self.room_multi,
                        'name': 'room',
                        'collapse': True,
                        'objects': sorted(rooms.iteritems()),
                    })

            if self.netbox:
                netboxes = {}
                for netbox in self.netbox_set:
                    room = room_name.get(netbox['room_id'])
                    netbox_name[netbox['id']] = self.netbox_label % netbox
                    if room in netboxes:
                        netboxes[room].append((netbox['id'], netbox_name[netbox['id']]))
                    else:
                        netboxes[room] = [(netbox['id'], netbox_name[netbox['id']])]

                output.append({
                        'label': 'IP device',
                        'button': self.button % 'IP device',
                        'multi': self.netbox_multi,
                        'name': 'netbox',
                        'objects': sorted(netboxes.iteritems()),
                    })

            if self.service:
                services = {}
                for service in self.service_set:
                    netbox = netbox_name[service['netbox_id']]
                    name = self.service_label % service
                    if netbox in services:
                        services[netbox].append((service['id'], name))
                    else:
                        services[netbox] = [(service['id'], name)]

                output.append({
                        'label': 'Service',
                        'button': self.button % 'service',
                        'multi': self.service_multi,
                        'name': 'service',
                        'collapse': True,
                        'objects': sorted(services.iteritems()),
                    })

            if self.module:
                modules = {}
                for module in self.module_set:
                    netbox = netbox_name[module['netbox_id']]
                    name = self.module_label % module
                    if netbox in modules:
                        modules[netbox].append((module['id'], name))
                    else:
                        modules[netbox] = [(module['id'], name)]

                output.append({
                        'label': 'Module',
                        'button': self.button % 'module',
                        'multi': self.module_multi,
                        'name': 'module',
                        'collapse': True,
                        'objects': sorted(modules.iteritems()),
                    })
            self.output = output

        template = get_template('webfront/quickselect.html')
        context  = Context({'output': self.output})

        result = template.render(context)

        if isinstance(result, unicode):
                result = result.encode('utf-8')

        return result
