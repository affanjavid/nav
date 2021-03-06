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
# pylint: disable=R0903
"""Serializers for the NAV REST api"""

from nav.models import manage, cabling
from rest_framework import serializers


class EntitySerializer(serializers.ModelSerializer):
    """Serializer for netboxentities"""
    serial = serializers.CharField(source='device')

    class Meta(object):
        model = manage.NetboxEntity
        fields = ('id', 'name', 'descr', 'serial', 'vendor_type',
                  'hardware_revision', 'firmware_revision', 'software_revision',
                  'mfg_name', 'model_name', 'fru', 'mfg_date')


class NetboxSerializer(serializers.ModelSerializer):
    """Serializer for the netbox model"""
    chassis = EntitySerializer(source='get_chassis', many=True)

    class Meta(object):
        model = manage.Netbox
        depth = 1


class PatchSerializer(serializers.ModelSerializer):
    """Serializer for the patch model"""
    class Meta(object):
        model = cabling.Patch
        depth = 2


class SpecificPatchSerializer(serializers.ModelSerializer):
    """Specific serializer used for InterfaceSerializer"""
    class Meta(object):
        model = cabling.Patch
        depth = 1
        fields = ('id', 'cabling', 'split')


class InterfaceSerializer(serializers.ModelSerializer):
    """Serializer for the interface model"""
    patches = SpecificPatchSerializer()

    class Meta(object):
        model = manage.Interface


class CablingSerializer(serializers.ModelSerializer):
    """Serializer for the cabling model"""
    class Meta(object):
        model = cabling.Cabling


class CamSerializer(serializers.ModelSerializer):
    """Serializer for the cam model"""
    class Meta(object):
        model = manage.Cam


class ArpSerializer(serializers.ModelSerializer):
    """Serializer for the arp model"""
    class Meta(object):
        model = manage.Arp


class UnrecognizedNeighborSerializer(serializers.ModelSerializer):
    """Serializer for the arp model"""
    class Meta(object):
        model = manage.UnrecognizedNeighbor


class RoomSerializer(serializers.ModelSerializer):
    """Serializer for the room model"""
    @staticmethod
    def transform_position(obj, _value):
        """Returns string versions of the coordinates"""
        if obj.position:
            lat, lon = obj.position
            return str(lat), str(lon)

    class Meta(object):
        model = manage.Room


class VlanSerializer(serializers.ModelSerializer):
    """Serializer for the vlan model"""
    class Meta(object):
        model = manage.Vlan


class PrefixSerializer(serializers.ModelSerializer):
    """Serializer for prefix model"""
    class Meta(object):
        model = manage.Prefix


class PrefixUsageSerializer(serializers.Serializer):
    """Serializer for prefix usage queries"""
    starttime = serializers.DateTimeField()
    endtime = serializers.DateTimeField()
    prefix = serializers.CharField()
    usage = serializers.FloatField()
    active_addresses = serializers.IntegerField()
    max_addresses = serializers.IntegerField()
    max_hosts = serializers.IntegerField()
    url_machinetracker = serializers.CharField()
    url_report = serializers.CharField()
    url_vlan = serializers.CharField()


class ServiceHandlerSerializer(serializers.Serializer):
    """Serializer for service handlers.

    These handlers does not exist in the database but as python modules.

    NB: Later versions of django rest framework supports list and dict
    fields. Then we can add the args and optargs.
    """

    name = serializers.CharField()
    ipv6_support = serializers.BooleanField()
    description = serializers.CharField()
