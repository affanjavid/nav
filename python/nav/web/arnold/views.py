#
# Copyright (C) 2012 (SD -311000) UNINETT AS
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
"""Views for Arnold

TODO:
- Check possibility of using model forms
- Add "Manual Detention"
- Styling
"""

from IPy import IP
from django.shortcuts import render_to_response, redirect
from django.template import RequestContext
from django.db.models import Q

from datetime import datetime, timedelta

from nav.models.arnold import (Identity, Justification, QuarantineVlan,
                               DetentionProfile)
from nav.django.utils import get_account
from nav.web.arnold.forms import (JustificationForm, HistorySearchForm,
                                  QuarantineVlanForm, SearchForm,
                                  DetentionProfileForm)
from nav.web.utils import create_title

NAVPATH = [('Home', '/'), ('Arnold', '/arnold')]


def create_context(path, context):
    """Create a dictionary for use in context based on path"""
    navpath = NAVPATH + [(path,)]
    path_context = {
        'navpath': navpath,
        'title': create_title(navpath)
    }
    return dict(path_context.items() + context.items())


def render_history(request):
    """Controller for rendering arnold history"""
    days = 7
    if 'days' in request.GET:
        form = HistorySearchForm(request.GET)
        if form.is_valid():
            days = form.cleaned_data['days']

    form = HistorySearchForm(initial={'days': days})

    identities = Identity.objects.filter(
        last_changed__gte=datetime.now() - timedelta(days=days))

    return render_to_response(
        'arnold/history.html',
        create_context('History',
                       {'active': {'history': True},
                        'form': form,
                        'identities': identities}),
        context_instance=RequestContext(request)
    )


def render_detained_ports(request):
    """Controller for rendering detained ports"""
    identities = Identity.objects.filter(
        Q(status='disabled') | Q(status='quarantined'))

    return render_to_response(
        'arnold/detainedports.html',
        create_context('Detentions',
                       {'active': {'detentions': True},
                        'identities': identities}),
        context_instance=RequestContext(request)
    )


def render_search(request):
    """Controller for rendering search"""
    search_result = []
    if request.method == 'POST':
        form = SearchForm(request.POST)
        if form.is_valid():
            search_result = process_searchform(form)
    else:
        form = SearchForm(initial={'searchtype': 'ip', 'status': 'any',
                                   'days': 7})

    return render_to_response('arnold/search.html',
                              create_context('Search', {
                                  'form': form,
                                  'search_result': search_result,
                                  'active': {'search': True}
                              }),
                              RequestContext(request))


def process_searchform(form):
    """Get searchresults based on form data"""
    extra = {}
    kwargs = {
        'last_changed__gte': datetime.now() - timedelta(
            days=form.cleaned_data['days'])
    }

    if form.cleaned_data['searchtype'] == 'ip':
        ip = IP(form.cleaned_data['searchvalue'])
        if ip.len() == 1:
            kwargs['ip'] = str(ip)
        else:
            extra['where'] = ["ip << '%s'" % str(ip)]
    else:
        key = form.cleaned_data['searchtype'] + '__icontains'
        kwargs[key] = form.cleaned_data['searchvalue']

    if form.cleaned_data['status'] != 'any':
        kwargs['status'] = form.cleaned_data['status']

    return Identity.objects.filter(**kwargs).extra(**extra)


def render_justifications(request, jid=None):
    """Controller for rendering detention reasons"""
    if request.method == 'POST':
        form = JustificationForm(request.POST)
        if form.is_valid():
            process_justification_form(form)
            return redirect('arnold-justificatons')
    elif jid:
        justification = Justification.objects.get(pk=jid)
        form = JustificationForm(initial={
            'justificationid': justification.id,
            'name': justification.name,
            'description': justification.description
        })
    else:
        form = JustificationForm()

    justifications = Justification.objects.all()

    return render_to_response(
        'arnold/justifications.html',
        create_context('Justifications',
                       {'active': {'justifications': True},
                        'form': form,
                        'justifications': justifications}),
        context_instance=RequestContext(request)
    )


def process_justification_form(form):
    """Add new justification based on form data"""
    name = form.cleaned_data['name']
    desc = form.cleaned_data['description']
    justificationid = form.cleaned_data['justificationid']

    if justificationid:
        justification = Justification.objects.get(pk=justificationid)
    else:
        justification = Justification()

    justification.name = name
    justification.description = desc

    justification.save()


def render_manual_detention(request):
    """Controller for rendering manual detention"""
    pass


def render_detention_profiles(request):
    """Controller for rendering predefined detentions"""
    profiles = DetentionProfile.objects.all()

    for profile in profiles:
        profile.active = True if profile.active == 'y' else False

    return render_to_response('arnold/detention_profiles.html',
                       create_context('Detention Profiles',
                                      {'active': {'detentionprofiles': True},
                                       'profiles': profiles}),
                       RequestContext(request))


def render_edit_detention_profile(request, did=None):
    """Controller for rendering edit of a detention profile"""
    profile = None

    if request.method == 'POST':
        form = DetentionProfileForm(request.POST)
        if form.is_valid():
            process_detention_profile_form(form, get_account(request))
            return redirect('arnold-detention-profiles')

    elif did:
        profile = DetentionProfile.objects.get(pk=did)

        profile.active = True if profile.active == 'y' else False
        profile.incremental = True if profile.incremental == 'y' else False
        qvlanid = profile.quarantine_vlan.id if profile.quarantine_vlan else \
        None

        form = DetentionProfileForm(initial={
            'detention_id': profile.id,
            'detention_type': profile.detention_type,
            'title': profile.name,
            'description': profile.description,
            'justification': profile.justification.id,
            'mail': profile.mailfile,
            'qvlan': qvlanid,
            'keep_closed': profile.keep_closed,
            'exponential': profile.incremental,
            'duration': profile.duration,
            'active_on_vlans': profile.active_on_vlans,
            'active': profile.active
        })
    else:
        form = DetentionProfileForm()


    return render_to_response('arnold/edit_detention_profile.html',
                              create_context('Detention Profile',
                                             {'form': form,
                                              'profile': profile}),
                              RequestContext(request))


def process_detention_profile_form(form, account):
    """Process add or edit of new form"""
    did = form.cleaned_data['detention_id']
    if did:
        profile = DetentionProfile.objects.get(pk=did)
    else:
        profile = DetentionProfile()

    profile.name = form.cleaned_data['title']
    profile.description = form.cleaned_data['description']
    profile.mailfile = form.cleaned_data['mail']
    profile.justification = Justification.objects.get(
        pk=form.cleaned_data['justification'])
    profile.keep_closed = form.cleaned_data['keep_closed']
    profile.incremental = 'y' if form.cleaned_data['exponential'] else 'n'
    profile.duration = form.cleaned_data['duration']
    profile.active = 'y' if form.cleaned_data['active'] else 'n'
    profile.last_edited = datetime.now()
    profile.edited_by = account.login
    profile.active_on_vlans = form.cleaned_data['active_on_vlans']
    profile.detention_type = form.cleaned_data['detention_type']
    if form.cleaned_data['qvlan']:
        profile.quarantine_vlan = QuarantineVlan.objects.get(
            pk=form.cleaned_data['qvlan'])

    profile.save()


def render_quarantine_vlans(request, qid=None):
    """Controller for rendering quarantine vlans"""
    if request.method == 'POST':
        form = QuarantineVlanForm(request.POST)
        if form.is_valid():
            process_quarantinevlan_form(form)
            return redirect('arnold-quarantinevlans')
    elif qid:
        qvlan = QuarantineVlan.objects.get(pk=qid)
        form = QuarantineVlanForm(initial={
            'qid': qvlan.id,
            'vlan': qvlan.vlan,
            'description': qvlan.description
        })
    else:
        form = QuarantineVlanForm()

    qvlans = QuarantineVlan.objects.all()

    return render_to_response(
        'arnold/quarantinevlans.html',
        create_context('Quarantine Vlans',
                       {'active': {'quarantinevlans': True},
                        'form': form,
                        'qvlans': qvlans}),
        context_instance=RequestContext(request)
    )


def process_quarantinevlan_form(form):
    """Add new quarantine vlan based on form data"""
    vlan = form.cleaned_data['vlan']
    desc = form.cleaned_data['description']
    qid = form.cleaned_data['qid']

    if qid:
        qvlan = QuarantineVlan.objects.get(pk=qid)
    else:
        qvlan = QuarantineVlan()

    qvlan.vlan = vlan
    qvlan.description = desc

    qvlan.save()


def render_details(request, did):
    """Controller for rendering details about an identity"""
    identity = Identity.objects.get(pk=did)

    return render_to_response('arnold/details.html',
                              create_context('Details', {'identity': identity}),
                              RequestContext(request))
