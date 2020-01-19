# myth-delete-settings-by-host

Simple script developed to delete all records in MythTV DB associated with given hostname.

Usefull to clean DB after undesired frontend settings initialization (development, config mistakes, frontend removal, etc).

What it does:

1.finds MythTV config.xml

2.parses config.xml for DB host, name, userid & password

3.logs in DB and:

  3.1 if launched without any param: lists all hostnames found in 'settings' DB table

  3.2 if launched with <param>: deletes all records with field 'hostname' equal to <param> in tables:
      'displayprofilegroups' 'housekeeping' 'jumppoints' 'keybindings' 'music_playlists' 'settings' 'weatherscreens'
      and all records with field 'host' equal to <param> in tables: 'internetcontent'. Script also deletes records in
      'displayprofiles' table referenced in 'displayprofilegroups' records for hostname equal to <param>

Enjoy!
