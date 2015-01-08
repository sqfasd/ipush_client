{
  'targets': [
    {
      'target_name': 'xcomet_client',
      'type': 'none',
      'dependencies': [
        'src/libxcomet_client.gyp:libxcomet_client',
        'examples/linux/linux_client_example.gyp:linux_client_example',
      ],
    },
  ],
}
