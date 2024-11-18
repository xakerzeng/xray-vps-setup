# xray-vps-setup
Xray vps setup ansible

## Скрипт

```bash
bash <(wget -qO- https://raw.githubusercontent.com/Akiyamov/xray-vps-setup/refs/heads/main/vps-setup.sh)
```

## Плейбук

[Ansible-galaxy](https://galaxy.ansible.com/ui/standalone/roles/Akiyamov/xray-vps-setup/install/)

## Ручная установка

Описана [здесь](https://gist.github.com/Akiyamov/bf39613c8e38451e9eaa9fad22f4f40a).  

## Почему не nginx, haproxy, 3x-ui, x-ui, marzban, sing-box...

Caddy сам получит сертификаты, поэтому нам не придется их получать через `acme.sh` или `certbot`.  
3X-UI и другие панели - нинужон. Сидеть и поднимать панель, чтобы потом сидеть и закрывать ее анальными заборами, когда можно поднять сам сервер и лишь заглушку куда проще. Если вы не исползьуете ноды на Marzban, то я не вижу смысла в них.  
Sing-box не используется как сервер лишь пока что, позже я добавлю выбор сервера, но это уже будет вкусовщина.  
WebSocker, RAW, gRPC и тд не используются вместо TCP, так как в этом нет особого смысла. Пока что. 


А еще аеза контора неадекватных школьников которые залетают в чат к штдог, начинают из обидки банить людей через вотебан и используют нейрокал в промокакашках. :godmode: