{
  'targets':[
    {
      'target_name':'linux_client_example',
      'type':'executable',
      'sources':[
        'main.cc',
      ],
      'include_dirs': [
        '../../',
      ],
      'cflags': [
        '-std=c++11 -pthread',
      ],
      'dependencies': [
        '../../src/libxcomet_client.gyp:libxcomet_client',
      ],
    },
  ]
}
