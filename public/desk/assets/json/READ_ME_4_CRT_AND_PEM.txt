Reference: https://stackoverflow.com/questions/10175812/how-to-generate-a-self-signed-ssl-certificate-using-openssl/46159022#46159022

Use following openssl command to generate .crt and .pem, replace placeholders with your values.
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout YOUR_CERT_FILE_NAME.pem -out YOUR_CERT_FILE_NAME.crt -subj "/C=US/ST=WA/L=Seattle/CN=YOUR_DOMAIN.COM/emailAddress=YOUR_EMAIL@DOMAIN.COM"