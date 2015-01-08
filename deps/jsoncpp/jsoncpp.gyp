{
  'targets':[
    {
      'target_name':'jsoncpp',
      'type':'static_library',
      'include_dirs': [
        './include',
      ],
      'sources':[
        'src/json_reader.cpp',
        'src/json_value.cpp',
        'src/json_writer.cpp',
      ],
    },
  ],
}

