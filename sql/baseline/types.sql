-- This SQL script inserts initial equipment vendors and types in the NAV
-- manage database.
--
-- It is not necessary to run this script in a transaction.  If executed on a
-- running installation, types and vendors that already exist will generate
-- errors, while the rest will be inserted as new records.


-- First, vendors
INSERT INTO vendor (vendorid) VALUES ('alcatel');
INSERT INTO vendor (vendorid) VALUES ('allied');
INSERT INTO vendor (vendorid) VALUES ('avaya');
INSERT INTO vendor (vendorid) VALUES ('breezecom');
INSERT INTO vendor (vendorid) VALUES ('cisco');
INSERT INTO vendor (vendorid) VALUES ('dlink');
INSERT INTO vendor (vendorid) VALUES ('hp');
INSERT INTO vendor (vendorid) VALUES ('symbol');
INSERT INTO vendor (vendorid) VALUES ('3com');
INSERT INTO vendor (vendorid) VALUES ('nortel');
INSERT INTO vendor (vendorid) VALUES ('juniper');


-- Then types
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('3com', 'PS40', '1.3.6.1.4.1.43.10.27.4.1', false, false, false, true, 'Portstack 40 hub');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('3com', 'SW1100', '1.3.6.1.4.1.43.10.27.4.1.2.1', NULL, NULL, false, true, 'Portswitch 1100');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('3com', 'SW3300', '1.3.6.1.4.1.43.10.27.4.1.2.2', NULL, NULL, false, true, 'Portswitch 3300');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('3com', 'SW9300', '1.3.6.1.4.1.43.1.16.2.2.2.1', NULL, NULL, false, true, 'Portswitch 9300');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('alcatel', 'alcatel6200', '1.3.6.1.4.1.6486.800.1.1.2.2.4.1.4', true, true, false, false, 'OmniStack LS 6200');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('alcatel', 'alcatel6200-X', '1.3.6.1.4.1.6486.800.1.1.2.2.4.1.3', true, true, false, false, 'Alcatel Omnistack LS 6200 (seems to be multiple IDs for this model)');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('alcatel', 'alcatel6800', '1.3.6.1.4.1.6486.800.1.1.2.1.6.1.1', NULL, NULL, false, false, 'Alcatel Omniswitch 6800');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cat3560G', '1.3.6.1.4.1.9.1.617', true, true, true, true, 'Catalyst 3560G');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cat6504', '1.3.6.1.4.1.9.1.657', true, true, true, true, 'Catalyst');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst2924XL', '1.3.6.1.4.1.9.1.183', true, true, true, true, 'Catalyst 2924 XL switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst2924XLv', '1.3.6.1.4.1.9.1.217', true, true, true, true, 'Catalyst 2924 XLv switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst295024', '1.3.6.1.4.1.9.1.324', true, true, NULL, true, 'Catalyst 2950-24');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst295024G', '1.3.6.1.4.1.9.1.428', true, true, true, true, 'Catalyst 2950G-24-E1 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst295048G', '1.3.6.1.4.1.9.1.429', true, true, true, true, 'Catalyst 295048G');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst297024TS', '1.3.6.1.4.1.9.1.561', true, true, true, true, 'Catalyst 2970');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst3508GXL', '1.3.6.1.4.1.9.1.246', true, true, true, true, 'Catalyst 3508 GXL switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst3524XL', '1.3.6.1.4.1.9.1.248', true, true, true, true, 'Catalyst 3524 XL switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst3524tXLEn', '1.3.6.1.4.1.9.1.287', true, true, true, false, 'Catalyst 3524tXLEn');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst375024ME', '1.3.6.1.4.1.9.1.574', true, true, true, false, 'Catalyst 3750 Metro');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst37xxStack', '1.3.6.1.4.1.9.1.516', true, true, true, true, 'Catalyst 3750');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst4003', '1.3.6.1.4.1.9.5.40', true, true, true, true, 'Catalyst 4003');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst4006', '1.3.6.1.4.1.9.1.448', true, true, true, true, 'Catalyst 4006 sup 2 L3 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst4506', '1.3.6.1.4.1.9.1.502', true, true, true, true, 'Catalyst 4506 sup4 L3 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst4510', '1.3.6.1.4.1.9.1.537', true, true, NULL, true, 'Catalyst 4510');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'catalyst6509', '1.3.6.1.4.1.9.1.283', true, true, true, true, 'Catalyst 6509');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1000', '1.3.6.1.4.1.9.1.40', true, true, NULL, true, 'Cisco 1000 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1003', '1.3.6.1.4.1.9.1.41', true, true, NULL, true, 'Cisco 1003 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1005', '1.3.6.1.4.1.9.1.49', true, true, false, true, 'Cisco 1005 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco10720', '1.3.6.1.4.1.9.1.397', true, true, true, true, 'Cisco 10720 (YB) Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco12016', '1.3.6.1.4.1.9.1.273', true, true, true, true, 'Cisco 12016 (GSR) Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco12404', '1.3.6.1.4.1.9.1.423', true, true, NULL, true, 'Cisco 12404 (GSR) Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco12416', '1.3.6.1.4.1.9.1.385', true, true, NULL, true, 'Cisco 12416 (GSR) Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1601', '1.3.6.1.4.1.9.1.113', true, true, NULL, true, 'Cisco 1601 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1602', '1.3.6.1.4.1.9.1.114', true, true, NULL, true, 'Cisco 1602 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1603', '1.3.6.1.4.1.9.1.115', true, true, NULL, true, 'Cisco 1603 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1604', '1.3.6.1.4.1.9.1.116', true, true, NULL, true, 'Cisco 1604 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1721', '1.3.6.1.4.1.9.1.444', true, true, NULL, true, 'Cisco 1721 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco1751', '1.3.6.1.4.1.9.1.326', true, true, NULL, true, 'Cisco 1751 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2500', '1.3.6.1.4.1.9.1.13', true, true, NULL, true, 'Cisco 2500 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2501', '1.3.6.1.4.1.9.1.17', true, true, NULL, true, 'Cisco 2501 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2502', '1.3.6.1.4.1.9.1.18', true, true, NULL, true, 'Cisco 2502 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2503', '1.3.6.1.4.1.9.1.19', true, true, NULL, true, 'Cisco 2503 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2511', '1.3.6.1.4.1.9.1.27', true, true, NULL, true, 'Cisco 2511 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2514', '1.3.6.1.4.1.9.1.30', true, true, NULL, true, 'Cisco 2514 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco2821', '1.3.6.1.4.1.9.1.577', true, true, NULL, true, 'Cisco 2821 router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco3620', '1.3.6.1.4.1.9.1.122', true, true, NULL, true, 'Cisco 3620 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco3640', '1.3.6.1.4.1.9.1.110', true, true, false, true, 'Cisco 3640 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco4000', '1.3.6.1.4.1.9.1.7', true, true, false, true, 'Cisco 4000 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco4500', '1.3.6.1.4.1.9.1.14', true, true, NULL, true, 'Cisco 4500 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco4700', '1.3.6.1.4.1.9.1.50', true, true, false, true, 'Cisco 4700 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7010', '1.3.6.1.4.1.9.1.12', true, true, NULL, true, 'Cisco 7010 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7204', '1.3.6.1.4.1.9.1.125', true, true, NULL, true, 'Cisco 7204 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7204VXR', '1.3.6.1.4.1.9.1.223', true, true, NULL, true, 'Cisco 7204VXR Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7206', '1.3.6.1.4.1.9.1.108', true, true, false, true, 'Cisco 7206 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7206VXR', '1.3.6.1.4.1.9.1.222', true, true, true, true, 'Cisco 7206VXR Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7505', '1.3.6.1.4.1.9.1.48', true, true, NULL, true, 'Cisco 7505 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7507', '1.3.6.1.4.1.9.1.45', true, true, true, true, 'Cisco 7507 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'cisco7513', '1.3.6.1.4.1.9.1.46', true, true, NULL, true, 'Cisco 7513 Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoAIRAP1130', '1.3.6.1.4.1.9.1.618', true, true, true, false, 'Cisco AP 1130');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoAIRAP1210', '1.3.6.1.4.1.9.1.525', true, NULL, false, true, 'Cisco AP 1200');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoAIRAP350IOS', '1.3.6.1.4.1.9.1.552', true, true, NULL, true, 'Cisco AP 350');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoAS5200', '1.3.6.1.4.1.9.1.109', true, true, NULL, true, 'Cisco AS5200');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoVPN3030', '1.3.6.1.4.1.3076.1.2.1.1.1.2', true, true, NULL, true, 'Cisco 3030 VPN concentrator');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'ciscoWSX5302', '1.3.6.1.4.1.9.1.168', true, true, NULL, true, 'Cisco RSM Router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc2926', '1.3.6.1.4.1.9.5.35', true, true, true, true, 'Catalyst 2926 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc2980g', '1.3.6.1.4.1.9.5.49', true, true, true, true, 'Catalyst 2980g');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc2980ga', '1.3.6.1.4.1.9.5.51', true, true, true, true, 'Catalyst 2980ga');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc4006', '1.3.6.1.4.1.9.5.46', true, true, true, true, 'Catalyst 4006 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc5000', '1.3.6.1.4.1.9.5.7', true, true, true, true, 'Catalyst 5000 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc5500', '1.3.6.1.4.1.9.5.17', true, true, true, true, 'Catalyst 5500 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('cisco', 'wsc5505', '1.3.6.1.4.1.9.5.34', true, true, true, true, 'Catalyst 5505 switch');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('hp', 'hp2524', '1.3.6.1.4.1.11.2.3.7.11.19', true, true, false, true, 'ProCurve Switch 2524');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('hp', 'hp2626A', '1.3.6.1.4.1.11.2.3.7.11.34', true, true, false, true, 'ProCurve Switch 2626 (J4900A)');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('hp', 'hp2626B', '1.3.6.1.4.1.11.2.3.7.11.45', true, true, false, false, 'ProCurve Switch 2626 (J4900B)');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('hp', 'hp2650A', '1.3.6.1.4.1.11.2.3.7.11.29', true, true, false, true, 'ProCurve Switch 2650 (J4899A)');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('hp', 'hp2650B', '1.3.6.1.4.1.11.2.3.7.11.44', true, true, false, true, 'ProCurve Switch 2650 (J4899B)');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('juniper', 'T640', '1.3.6.1.4.1.2636.1.1.1.2.6', true, true, NULL, true, 'Juniper T640');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('juniper', 'juniperM7i', '1.3.6.1.4.1.2636.1.1.1.2.10', true, true, NULL, true, 'Juniper Networks, Inc. m7i internet router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('juniper', 'm320', '1.3.6.1.4.1.2636.1.1.1.2.9', true, true, false, false, 'Juniper Networks, Inc. m320 internet router');
INSERT INTO "type" (vendorid, typename, sysobjectid, cdp, tftp, cs_at_vlan, chassis, descr) VALUES ('nortel', 'nortel5510', '1.3.6.1.4.1.45.3.53.1', false, false, false, false, 'Nortel Baystack 5510-48T Switch');
