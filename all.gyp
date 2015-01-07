{
  'variables': {
  },
  'include': [''],
  'condition': [
    ['OS=="linux"', {
      'targets': [
        {
          'target_name': 'xcomet_client_tool',
          'type': 'executable',
          'dependencies': [
            'libxcomet_client'
          ],
          'sources': [
          ],
        },
      ]
    }],

    ['OS=="android"', {
    }],

    ['OS=="ios"', {
    }],
  ],

  'targets': [
    {
      'target_name': 'libxcomet_client',
      'type': 'static_library',
      'dependencies': [
        'deps/jsoncpp:jsoncpp',
      ],
      'sources': [
        'src/socketclient.cc',
      ],
      'cflags': [
        '-std=c++11 -pthread',
      ],
      'libraries': [
        ''
      ],
    },
  ],
}
