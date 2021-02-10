# README

0. Seteo de lenguaje de programacion
Se requiere de Ruby 2.4.0 Luego de la instalacion de ruby 2.4.0 se debe ejecutar:
    $ rvm default 2.4.0
    $ bundle install


Para setear el entorno de trabajo se debe:
1. Iniciar la base de datos local con postgresql (si es MacOsX se utiliza brew services).
    Para problemas con el archivo .pid:
    None of the above worked for me. I had to reinstall Postgres the following way :

        Uninstall postgresql with brew : brew uninstall postgresql
        brew doctor (fix whatever is here)
        brew cleanup
        Remove all Postgres folders :

        rm -r /usr/local/var/postgres
        rm -r /Users/<username>/Library/Application\ Support/Postgres
        Reinstall postgresql with brew : brew install postgresql

        Start server : brew services start postgresql
        You should now have to create your databases... (createdb)
    
    Una vez instalado postgresql se debe iniciar la BD local:
    $ brew services start postgresql

    Para terminar con el servicio de BD local:
    $ brew services stop postgresql

    Para reiniciar el servicio de BD local:
    $ brew servicres restart postgresql

2. Se debe crear el archivo database.yml, donde en username se coloca el nombre de usuario del computador host.

3. Para correr la aplicacion siempre utilizar RAILS_ENV=default
4. Crear la base de datos:
    $ RAILS_ENV=default rake db:create
    $ RAILS_ENC=default rake db:migrate
5. Poblar con los alumnos del curso con el .json (TO DO)

Ejecutar servidor:
6. Cada vez que se desee ejecutar el servidor se debe poner en consola:
    $ RAILS_ENV=default rails server


NOTA: Para problemas al correr rails c:
    $ DISABLE_PRY_RAILS=1 RAILS_ENV=default rails c  