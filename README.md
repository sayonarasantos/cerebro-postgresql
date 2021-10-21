# Lembre de comandos


## Comandos psql

- Conectar com servidor remoto:
```bash
psql -h host_name -p host_port -U user_name -b database_name -W 
```

- Restaurar banco:
```bash
psql -U user_name -h host_name -W -d database_name < sql_retore_file
```


## Comandos SQL

- Remover banco:
```sql
DROP DATABASE database_name;
```

- Conceder todas as permissões do banco ao usuário:
```sql
GRANT CONNECT ON DATABASE database_name TO user_name;
GRANT USAGE ON SCHEMA schema_name TO user_name;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA schema_name TO user_name;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA schema_name TO user_name;
```
