# -*- coding: utf-8 -*-
import os

from unipath import Path
from fabric.api import *


env.kits = {
    'swat4': {
        'mod': 'Mod',
        'content': 'Content',
        'server': 'Swat4DedicatedServer.exe',
        'ini': 'Swat4DedicatedServer.ini',
    },
    'swat4exp': {
        'mod': 'ModX',
        'content': 'ContentExpansion',
        'server': 'Swat4XDedicatedServer.exe',
        'ini': 'Swat4XDedicatedServer.ini',
    },
}

env.roledefs = {
    'ucc': ['vm-ubuntu-swat'],
    'server': ['vm-ubuntu-swat'],
}

env.paths = {
    'here': Path(os.path.dirname(__file__)).parent,
}
env.paths.update({
    'dist': env.paths['here'].child('dist'),
    'compiled': env.paths['here'].child('compiled'),
})

env.ucc = {
    'path': Path('/home/sergei/swat4ucc/'),
    'git': 'git@home:public/swat4#origin/ucc',
    'packages': (
        ('Utils', 'git@home:swat/swat-utils'),
        ('HTTP', 'git@home:swat/swat-http'),
        ('MOTD', 'git@home:swat/swat-motd'),
    ),
}

env.server = {
    'path': Path('/home/sergei/swat4server/'),
    'git': 'git@home:public/swat4#origin/server-vip',
    'settings': {
        '+[Engine.GameEngine]': (
            'ServerActors=Utils.Package',
            'ServerActors=HTTP.Package',
            'ServerActors=MOTD.Core',
        ),
        '[Julia.Core]': (
            'Enabled=True',
        ),
        '[MOTD.Core]': (
            'Enabled=True',
            'URL=http://www.mytteam.com/motd/team',
            'MaxMessages=2',
        ),
    }
}

env.dist = {
    'version': '1.0.0',
    'extra': (
        env.paths['here'].child('LICENSE'),
        env.paths['here'].child('README.html'),
        env.paths['here'].child('CHANGES.html'),
    )
}