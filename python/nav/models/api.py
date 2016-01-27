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
"""Models for the NAV API"""

from datetime import datetime
from django.db import models
from django_hstore import hstore
from nav.models.fields import VarcharField
from nav.models.profiles import Account


class APIToken(models.Model):
    """APItokens are used for authenticating to the api

    Endpoints may be connected to the token in which case the token also works
    as an authorization token.
    """

    token = VarcharField()
    expires = models.DateTimeField()
    created = models.DateTimeField(auto_now_add=True)
    client = models.ForeignKey(Account, db_column='client')
    scope = models.IntegerField(null=True, default=0)
    comment = models.TextField(null=True, blank=True)
    revoked = models.BooleanField(default=False)
    last_used = models.DateTimeField(null=True)
    endpoints = hstore.DictionaryField()

    objects = hstore.HStoreManager()

    def __unicode__(self):
        return self.token

    def is_expired(self):
        """Check is I am expired"""
        return self.expires < datetime.now()

    class Meta(object):
        db_table = 'apitoken'
