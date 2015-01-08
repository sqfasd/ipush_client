{
  'targets':[
    {
      'target_name':'libxcomet_client',
      'type':'static_library',
      'sources':[
        'socketclient.cc',
      ],
      'include_dirs': [
        '../deps/',
      ],
      'cflags': [
        '-std=c++11 -pthread',
      ],
      'dependencies': [
        '../deps/jsoncpp/jsoncpp.gyp:jsoncpp',
      ],
    },
  ]
}
