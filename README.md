# 🛡️ Escudo Digital contra Ataques Web (Firewall con iptables)

Imagina que tu servidor web es una tienda popular. Si de pronto entran miles de personas falsas solo a hacer preguntas tontas o a amontonarse en la puerta, los clientes reales no podrán entrar. Eso es un ataque de denegación de servicio (DoS).

Este script de Linux actúa como un **guardia de seguridad inteligente** en la entrada de tu servidor para detectar y bloquear a los tramposos en milisegundos, manteniendo la tienda abierta para tus usuarios reales.

---

## ⚡ ¿Qué hace este "guardia de seguridad" exactamente?

El script aplica tres capas de protección automáticas:

1. **Pase VIP para clientes conocidos (Optimización):** Si un usuario ya ingresó a la página de forma correcta, el guardia lo reconoce de inmediato y lo deja pasar libremente. Así no gasta tiempo revisándolo una y otra vez.
2. **Detector de trampas en la web (Capa 7):** Si alguien intenta descargar de forma masiva un archivo muy pesado y peligroso (en este caso, un archivo llamado `db.sql` que podría romper la base de datos), el guardia lo detecta por su "nombre" y lo expulsa inmediatamente.
3. **Control de multitudes en la puerta (Capa 4 - SYN Flood):** Si un atacante intenta inundar el servidor con miles de llamadas falsas por segundo para saturar las líneas tanto en la web normal (HTTP) como en la segura (HTTPS), el script pone un límite de velocidad. Solo deja pasar un máximo de 10 peticiones por segundo. Todo lo que supere eso, va directo a la basura.

---

## 🚀 ¿Por qué esta versión es mejor que la anterior?

Si usabas la versión antigua, podías tener problemas. Aquí te explico por qué cambiamos las reglas del juego:

* **No se olvida de nada (Idempotente):** La versión anterior borraba las reglas una por una antes de empezar, lo que podía fallar. Esta versión crea una "zona de defensa" exclusiva. Cada vez que inicias el script, esa zona se limpia por completo con un solo botón y se vuelve a armar desde cero. Así evitas duplicar miles de reglas que congelarían el procesador de tu servidor.
* **No le da 'lag' a los usuarios:** Al incluir el "Pase VIP" (`ESTABLISHED,RELATED`), los usuarios que ya están jugando o navegando legítimamente no experimentan lentitud (como pasaba en el juego 2048).
* **Protección Doble (HTTP y HTTPS):** La versión anterior solo protegía la puerta trasera (puerto 80). Esta nueva versión también protege la puerta principal segura (puerto 443).

---

## 🛠️ Cómo usarlo en tu servidor Linux

1. Guarda el código en tu servidor con el nombre `defensa.sh`.
2. Dale permisos para que pueda ejecutarse como un programa:
   ```bash
   chmod +x defensa.sh
