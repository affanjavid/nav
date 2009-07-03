# -*- coding: utf-8 -*-
#
# Copyright (C) 2008-2009 UNINETT AS
#
# This file is part of Network Administration Visualized (NAV).
#
# NAV is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.  You should have received a copy of the GNU General Public License
# along with NAV. If not, see <http://www.gnu.org/licenses/>.
#

from datetime import datetime

from django.db.models import Q
from django.utils.datastructures import SortedDict

from nav.models.event import AlertHistory, AlertHistoryMessage
from nav.models.manage import Netbox, Device
from nav.web.quickselect import QuickSelect

def get_selected_types(types):
    selected_types = {'event': [], 'alert': []}
    for type in types:
        if type.find('_') != -1:
            splitted = type.split('_')
            if splitted[0] == 'e':
                selected_types['event'].append(splitted[1])
            else:
                selected_types['alert'].append(splitted[1])
    return selected_types

def fetch_history(selection, from_date, to_date, selected_types=[], order_by=None):
    def type_query_filter(selected_types):
        type_filter = []
        if selected_types['event']:
            type_filter.append(Q(event_type__in=selected_types['event']))
        if selected_types['alert']:
            type_filter.append(Q(alert_type__in=selected_types['alert']))
        return type_filter

    type_filter = type_query_filter(selected_types)

    netbox = Netbox.objects.select_related(
        'device'
    ).filter(
        Q(id__in=selection['netbox']) |
        Q(room__in=selection['room']) |
        Q(room__location__in=selection['location'])
    )

    device = Device.objects.filter(
        Q(netbox__in=selection['netbox']) |
        Q(netbox__module__in=selection['module'])
    )

    history = AlertHistory.objects.select_related(
        'event_type', 'alert_type', 'device',
        'netbox', 'netbox__room', 'netbox__room__location'
    ).filter(
        Q(netbox__in=[n.id for n in netbox]) |
        Q(device__in=[n.device.id for n in netbox]) |
        Q(device__in=[d.id for d in device]),
        *type_filter
    ).extra(
        where=[
            '''
            start_time >= %s AND (
                (
                   (end_time IS NULL OR end_time = 'infinity') AND
                   start_time < %s
               ) OR
               end_time < %s
           )
           '''
        ],
        params=[from_date, to_date, to_date]
    ).order_by('-start_time', '-end_time')

    return history

def get_page(paginator, page):
    try:
        history = paginator.page(page)
    except (EmptyPage, InvalidPage):
        history = paginator.page(paginator.num_pages)
    return history

def get_messages_for_history(alert_history):
    msgs = AlertHistoryMessage.objects.filter(
        alert_history__in=[h.id for h in alert_history],
        language='en',
    ).values('alert_history', 'message', 'type', 'state')
    return msgs

def group_history_and_messages(history, messages, group_by=None):
    def get_grouping_key(a, group_by):
        if group_by == "location":
            key = a.netbox.room.location.description
        elif group_by == "room":
            key = a.netbox.room.description
        #elif group_by == "module":
        #    key = a.module_name
        elif group_by == "device":
            key = a.device.serial
        elif group_by == "datetime":
            key = a.start_time.date().isoformat()
        else:
            key = a.netbox.sysname
        return key

    grouped_history = SortedDict()
    for a in history:
        a.extra_messages = {}
        for m in messages:
            if a.id == m['alert_history']:
                if not a.extra_messages.has_key(m['state']):
                    a.extra_messages[m['state']] = {
                        'sms': None,
                        'email': None,
                        'jabber': None,
                    }
                a.extra_messages[m['state']][m['type']] = m['message']

        key = get_grouping_key(a, group_by)

        if not grouped_history.has_key(key):
            grouped_history[key] = []
        grouped_history[key].append(a)
    return grouped_history
