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
        ('MOTD', 'git@home:swat/swat-motd#origin/develop'),
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
            #'URL=http://www.mytteam.com/motd/team',
            'URL=http://192.168.56.1:8000/api/motd/summary/?initial=10',
            'URL=http://192.168.56.1:8000/api/motd/leaderboard/?initial=20',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/score/?initial=20',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/time/?initial=30',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/spr/?initial=40',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/kdr/?initial=50',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/coop_score/?initial=60',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/coop_time/?initial=70',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/coop_wins/?initial=80',
            # 'URL=http://192.168.56.1:8000/api/motd/leaderboard/coop_games/?initial=90',
            #'MaxMessages=2',
        ),
    }
}

env.dist = {
    'version': '1.2.0',
    'extra': (
        env.paths['here'].child('LICENSE'),
        env.paths['here'].child('README.html'),
        env.paths['here'].child('CHANGES.html'),
    )
}