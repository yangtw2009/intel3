name: Deploy to Remote Server via frp

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Install SSH Client
        run: sudo apt-get install -y openssh-client

      - name: Install frp client
        run: |
          wget https://github.com/fatedier/frp/releases/download/v0.38.0/frp_0.38.0_linux_amd64.tar.gz
          tar -xzf frp_0.38.0_linux_amd64.tar.gz
          cd frp_0.38.0_linux_amd64
          echo -e "[common]\nserver_addr = ${{ secrets.SERVER_IP }}\nserver_port = 7000\nprivilege_token = ${{ secrets.FRP_TOKEN }}\n\n[ssh]\ntype = tcp\nlocal_ip = 127.0.0.1\nlocal_port = 22\nremote_port = 7090" > frpc.ini
          nohup ./frpc -c frpc.ini &

      - name: Copy files to server
        env:
          SSHPASS: ${{ secrets.SERVER_PASSWORD }}
        run: |
          sudo apt-get install -y sshpass
          sshpass -e scp -o StrictHostKeyChecking=no -P 7090 -r . ${{ secrets.SERVER_USERNAME }}@${{ secrets.SERVER_IP }}:/home/pi/project

      - name: Deploy application
        env:
          SSHPASS: ${{ secrets.SERVER_PASSWORD }}
        run: |
          sshpass -e ssh -o StrictHostKeyChecking=no -p 7090 ${{ secrets.SERVER_USERNAME }}@${{ secrets.SERVER_IP }} 'bash -s' < ./deploy-script.sh
