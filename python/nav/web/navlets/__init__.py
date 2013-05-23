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
"""Navlets - the NAV version of portlets

To use create a Navlet do the following:
- create a module in nav.web.navlets
- create a class in the module that inherits Navlet
  - add at least title and description
  - override at least the 'get_template_basename' method
- add the modulestring to settings.py
  - nav.web.navlets.<module>.<class>
- create a template for at least the view mode
  - it must be named <result_from_get_template_basename>_view.html

Context:
- context is added by overriding 'get_context_data'
  - remember to call super
  - remember to return the new context

If you want the navlet to have prefereneces:
- set class attribute is_editable to True in your class
- create a template for the edit mode that submits a form with the preferences
  - This form will be submitted by javascript, see below
- create at least a post method for storing the preferences
- the preferences are available as navlet.preferences in the template

Templates
- A form in editmode will be submitted automatically by javascript. Make sure
  to return a HttpResponse from the post method. This is done to
  allow reloading only the navlet to display the changes after the post

"""

NAVLET_MODE_VIEW = 'VIEW'
NAVLET_MODE_EDIT = 'EDIT'

NAVLET_COLUMN_1 = 1
NAVLET_COLUMN_2 = 2

import logging
import simplejson
from collections import namedtuple

from django.conf import settings
from django.core.urlresolvers import reverse
from django.db.models import Max
from django.http import HttpResponse
from django.shortcuts import redirect
from django.views.generic.base import TemplateView

from nav.models.profiles import AccountNavlet
from nav.django.auth import get_sudoer
from nav.django.utils import get_account

_logger = logging.getLogger(__name__)

NavletContainer = namedtuple('NavletContainer', 'identifier title description')


class Navlet(TemplateView):
    """Base class for navlets"""

    title = 'Navlet'
    description = 'No description'
    is_editable = False
    preferences = {}
    navlet_id = None

    def get_mode(self):
        """Fetch the mode of this request"""
        return self.request.REQUEST.get('mode', NAVLET_MODE_VIEW)

    def get_template_basename(self):
        """Should return the base template name

        The full template name will be based on this on the following format:
        <template_base_name>_(edit|view).html
        """
        raise NotImplementedError

    def get_template_names(self):
        """Get template name based on navlet mode"""
        self.mode = self.get_mode()
        if self.mode == NAVLET_MODE_VIEW:
            return 'navlets/%s_view.html' % self.get_template_basename()
        elif self.mode == NAVLET_MODE_EDIT:
            return 'navlets/%s_edit.html' % self.get_template_basename()
        else:
            return 'navlets/%s_view.html' % self.get_template_basename()

    def get_context_data(self, **kwargs):
        context = super(Navlet, self).get_context_data(**kwargs)
        context['navlet'] = self
        return context


def list_navlets(request):
    """Gives a json-response with all navlets modulestring, title and desc"""
    return HttpResponse(simplejson.dumps(get_navlets()))


def get_navlets():
    """Gets all installed navlet classes"""
    navlets = []

    for navletmodule in settings.NAVLETS:
        cls = get_navlet_from_name(navletmodule)
        if cls:
            navlets.append(NavletContainer(navletmodule,
                                           cls.title,
                                           cls.description))
    return navlets


def get_navlet_from_name(navletmodule):
    """Returns the correct class based on the modulestring"""
    lastmod, clsname = navletmodule.split('.')[-2:]
    try:
        module = __import__(navletmodule[:navletmodule.rfind('.')],
                            fromlist=[lastmod])
        cls = getattr(module, clsname)
    except AttributeError:
        _logger.error('Could not import %s' % navletmodule)
    else:
        return cls


def get_user_navlets(request):
    """Gets all navlets that this user subscribes to"""
    account = get_account(request)
    usernavlets = AccountNavlet.objects.filter(account=account)

    navlets = []
    for usernavlet in usernavlets:
        url = reverse('get-user-navlet', kwargs={'navlet_id': usernavlet.id})
        navlets.append({'id': usernavlet.id, 'url': url,
                        'column': usernavlet.column})
    return HttpResponse(simplejson.dumps(navlets))


def dispatcher(request, navlet_id):
    """Dispatch the correct navlet based on navlet_id

    The as_view method takes any attribute and adds it to the instance
    as long as it is defined on the Navlet class
    """
    account = get_account(request)
    account_navlet = AccountNavlet.objects.get(account=account, pk=navlet_id)
    cls = get_navlet_from_name(account_navlet.navlet)
    view = cls.as_view(preferences=account_navlet.preferences,
                       navlet_id=navlet_id)
    return view(request)


def add_user_navlet(request):
    """Add a navlet subscription to this user"""
    if request.method == 'POST' and 'navlet' in request.POST:
        account = get_account(request)

        if can_modify_navlet(account, request):
            add_navlet(account, request)

    return redirect('webfront-index')


def add_navlet(account, request):
    """Create new accountnavlet based on request data"""
    accountnavlet = AccountNavlet(account=account,
                                  navlet=request.POST.get('navlet'))
    accountnavlet.column, accountnavlet.order = find_new_placement(account)
    accountnavlet.save()


def find_new_placement(account):
    """Determines the best placement for a new account navlet"""
    colcount1 = account.accountnavlet_set.filter(
        column=NAVLET_COLUMN_1).count()
    colcount2 = account.accountnavlet_set.filter(
        column=NAVLET_COLUMN_2).count()

    if colcount1 <= colcount2:
        column = 1
        order = colcount1 + 1
    else:
        column = 2
        order = colcount2 + 1

    return column, order


def can_modify_navlet(account, request):
    """Determine if this account can modify navlets"""
    return not (account.is_default_account() and not get_sudoer(request))


def modify_navlet(func, account, request, error_message):
    """Modify the navlet using func"""
    if can_modify_navlet(account, request):
        try:
            func(account, request)
        except AccountNavlet.DoesNotExist:
            return HttpResponse(content=error_message, status=500)
        else:
            return HttpResponse()
    else:
        return HttpResponse(status=401)


def remove_user_navlet(request):
    """Remove a navlet-subscription from this user"""
    if request.method == 'POST' and 'navletid' in request.POST:
        account = get_account(request)
        return modify_navlet(remove_navlet, account, request,
                             "Error removing Navlet")

    return HttpResponse(status=400)


def remove_navlet(account, request):
    """Remove accountnavlet based on request data"""
    navlet_id = int(request.POST.get('navletid'))
    accountnavlet = AccountNavlet(pk=navlet_id, account=account)
    accountnavlet.delete()


def save_navlet_order(request):
    """Save the order of the navlets after a sort"""
    if request.method == 'POST':
        account = get_account(request)
        return modify_navlet(save_order, account, request,
                             "Error saving order")

    return HttpResponse(status=400)


def save_order(account, request):
    """Update navlets with new placement data"""
    orders = simplejson.loads(request.body)
    for key, value in orders['column1'].items():
        update_navlet(account, key, value, NAVLET_COLUMN_1)
    for key, value in orders['column2'].items():
        update_navlet(account, key, value, NAVLET_COLUMN_2)


def update_navlet(account, key, value, column):
    """Save the column and order of an account navlet"""
    key = int(key)
    navlet = AccountNavlet.objects.get(account=account, pk=key)
    navlet.order = value
    navlet.column = column
    navlet.save()

