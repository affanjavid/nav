#
# Copyright (C) 2013 UNINETT AS
#
# This file is part of Network Administration Visualized (NAV).
#
# NAV is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.  You should have received a copy of the GNU General Public
# License along with NAV. If not, see <http://www.gnu.org/licenses/>.
#
"""Status navlet"""
import simplejson
from datetime import datetime
from django.http import HttpResponse
from django.shortcuts import redirect

from nav.django.utils import get_account
from nav.models.manage import Netbox
from nav.models.profiles import AccountNavlet
from nav.web.navlets import (Navlet, REFRESH_INTERVAL, NAVLET_MODE_VIEW,
                             NAVLET_MODE_EDIT)
from nav.web.webfront.utils import boxes_down


class StatusNavlet(Navlet):
    """Navlet for displaying status"""

    title = "Status"
    description = "Shows status for your ip-devices and services"
    refresh_interval = 1000 * 60 * 10  # Refresh every 10 minutes
    is_editable = True

    def get_template_basename(self):
        return "status"

    def get_context_data(self, **kwargs):
        context = super(StatusNavlet, self).get_context_data(**kwargs)

        if self.mode == NAVLET_MODE_VIEW:
            down = boxes_down()
            num_shadow = 0
            for box in down:
                if box.netbox.up == Netbox.UP_SHADOW:
                    num_shadow += 1

            context['boxes_down'] = down
            context['num_shadow'] = num_shadow
            context['date_now'] = datetime.today()
        elif self.mode == NAVLET_MODE_EDIT:
            navlet = AccountNavlet.objects.get(pk=self.navlet_id)
            context['interval'] = navlet.preferences[REFRESH_INTERVAL] / 1000

        return context

    def post(self, request):
        account = get_account(request)
        try:
            interval = int(request.POST.get('interval')) * 1000
        except ValueError:
            return HttpResponse(status=400)

        try:
            navlet = AccountNavlet.objects.get(pk=self.navlet_id,
                                               account=account)
        except AccountNavlet.DoesNotExist:
            return HttpResponse(status=404)
        else:
            navlet.preferences[REFRESH_INTERVAL] = interval
            navlet.save()
            return HttpResponse(simplejson.dumps(navlet.preferences))
