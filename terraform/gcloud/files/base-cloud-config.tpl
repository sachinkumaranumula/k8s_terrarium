#cloud-config
hostname: ${node_name}
fqdn: ${node_name}
prefer_fqdn_over_hostname: true

groups:
  - k8s_admin: [k8s_contrib]

users:
  - name: k8s_contrib
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    groups: sudo, k8s_admin
    shell: /bin/bash
    lock_passwd: false
    # k8s4ever
    passwd: $6$HdYO6yfPB$avhH9fvDl9ihe.O8zgBg97AVffqMIrK9IlRf7ostJj8bsQ3Om20ZCPP.7zn3wbqf4SL.4pLrvmpMRESYwJy2x.

write_files:
  - path: /home/k8s_contrib/.vimrc
    permissions: "0664"
    content: |
      syntax enable
      set tabstop=2              " number of visual spaces per TAB
      set softtabstop=2          " number of spaces in tab when editing
      set shiftwidth=2           " c style indent
      set expandtab              " tabs = spaces
      set autoindent smartindent " follow indent style
      set number ruler           " show line numbers
      filetype indent on         " load filetype specific indent files in ~/.vim/indent/*.vim