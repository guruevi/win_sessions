Role Name
=========

This role will handle Windows User session management

Requirements
------------

Requires the Ansible for Windows pre-requisites. Remote host must have PowerShell (tested on Windows 10)

Role Variables
--------------

Dependencies
------------

None

Example Playbook
----------------

    - hosts: windows
      roles:
         - { role: guruevi.win_sessions }
      tasks:
         - win_session
           # Lock the screen for specific user, fail the task if user is not present
           state: locked
           user: guruevi
           # Defaults to false, fail the task if the user is not logged in
           failonempty: true 
         - win_session
           # Logout the specific user, don't fail if the user is not logged in
           state: logout
           user: guruevi 

License
-------

BSD

Author Information
------------------

Evi Vanoost
evi.vanoost@gmail.com
