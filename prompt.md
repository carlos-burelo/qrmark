# Eres un desarrollador backend experto en BunJS y TypeScript. Tu tarea es crear un backend completo para una aplicación de gestión de eventos. La aplicación debe permitir a los usuarios crear, gestionar y asistir a eventos, así como enviar invitaciones y notificaciones. El backend debe ser capaz de manejar múltiples usuarios y eventos simultáneamente, asegurando la integridad de los datos y el rendimiento del sistema.
# La aplicación debe incluir las siguientes entidades y sus relaciones:
Considerando estos esquemas y modelos, quiero que implementes el backend entero usando BunJS y TypeScript. El backend debe incluir las siguientes funcionalidades:
- Autenticación y autorización de usuarios (JWT). hono/jwt
- CRUD para usuarios, eventos, ubicaciones, asistencia, listas de distribución e invitaciones.
- Generación de códigos QR para check-in y check-out.
- Envío de notificaciones a los usuarios.
- Manejo de roles y permisos (moderador, organizador, usuario).
- Manejo de eventos recurrentes.
- Manejo de listas de distribución y sus miembros.
- Manejo de invitaciones a eventos.
- Manejo de asistencia a eventos.
- Manejo de notificaciones.
- Manejo de tokens QR.
- Manejo de ubicaciones.
- Manejo de eventos.
- Manejo de usuarios.
- Manejo de autenticación y autorización.
- Manejo de roles y permisos.

- crea un driver de base de datos para mysql mysql2/promise
- los endpoints deben ser RESTful y seguir las mejores prácticas de diseño de API.
- los endpoints deben tener validaciones y manejo de errores adecuado. (@hono/zod-validator)
- enfoca el diseño del codigo a uno modular y escalable, utilizando patrones de diseño.
- usa clases y objetos para representar los modelos de datos y la lógica de negocio.
- IMPORTANTE: el backend debe ser capaz de manejar múltiples usuarios y eventos simultáneamente, asegurando la integridad de los datos y el rendimiento del sistema.
- IMPORTANTE: Debes crear clases de utilidad siempre que sea posible para evitar la duplicación de código y mejorar la mantenibilidad del sistema.

Debes implementar el 100% del codigo del backend esta estrictamente prohibido usar cualquier otro framework o librería que no sea BunJS, Mysql2, @hono/zod-validator y TypeScript.

como resultado final, quiero un proyecto de backend completo y funcional que cumpla con todos los requisitos mencionados anteriormente. El código debe estar bien estructurado y seguir las mejores prácticas de desarrollo de software.

el codigo debe ser limpio, legible y fácil de mantener.

ESTA ESTRICTAMENTE PROHIBIDO COLOCAR COMENTARIOS EN EL CODIGO O DOCUMENTARLO (DEBE PODER SER LEÍDO Y COMPRENDIDO SIN NECESIDAD DE EXPLICACIONES)


la base de datos debe ser MYSQL DE PREFERENCIA CREA PROCEDIMIENTO ALMACENADOS, TRIGGERS, FUNCIONES Y EVENTOS PARA DELEGARLE PARTE DEL TRABAJO A LA DB.


UNICAMENTE QUIERO EL CODIGO DEL BACKEND, TE ENVIO LOS MODELOS DE FLUTTER PARA QUE SEPAS QUE YA SE ESTA TRABAJANDO TAMBIEN EN LA APP MOVIL.

QUIERO EL BACKEND EN UN SOLO ARCHIVO MUY COMPLETO Y MUY MODULAR.


USA CLASES EN TODO MOMENTO.


COMO DATO ADICIONAL LOS QR NO TIENE FORMA DIRECTA DE SABER SI SON UTILIZADOS MAS QUE CUANDO HAY UNA FECHA DE CHECKING/CHECKOUT REGISTRADOS, SACA TODAS LAS CONSULTAS Y OPERACIONES A PROCEDIMIENTOS ALMACENADOS PARA QUE LA LOGICA NO ESTE EN LA CAPA DE APLICACION.


como contexto adicional esta es la documentacion de hono/jwt:

JWT Auth Middleware
The JWT Auth Middleware provides authentication by verifying the token with JWT. The middleware will check for an Authorization header if the cookie option is not set.
INFO
The Authorization header sent from the client must have a specified scheme.
Example: Bearer my.token.value or Basic my.token.value
Import
ts

import { Hono } from 'hono'
import { jwt } from 'hono/jwt'
import type { JwtVariables } from 'hono/jwt'
Usage
ts

// Specify the variable types to infer the `c.get('jwtPayload')`:
type Variables = JwtVariables

const app = new Hono<{ Variables: Variables }>()

app.use(
  '/auth/*',
  jwt({
    secret: 'it-is-very-secret',
  })
)

app.get('/auth/page', (c) => {
  return c.text('You are authorized')
})
Get payload:
ts

const app = new Hono()

app.use(
  '/auth/*',
  jwt({
    secret: 'it-is-very-secret',
  })
)

app.get('/auth/page', (c) => {
  const payload = c.get('jwtPayload')
  return c.json(payload) // eg: { "sub": "1234567890", "name": "John Doe", "iat": 1516239022 }
})
TIP
jwt() is just a middleware function. If you want to use an environment variable (eg: c.env.JWT_SECRET), you can use it as follows:
js

app.use('/auth/*', (c, next) => {
  const jwtMiddleware = jwt({
    secret: c.env.JWT_SECRET,
  })
  return jwtMiddleware(c, next)
})
Options
required secret: string**
A value of your secret key.
optional cookie: string**
If this value is set, then the value is retrieved from the cookie header using that value as a key, which is then validated as a token.
optional alg: string**
An algorithm type that is used for verifying. The default is HS256.
Available types are HS256 | HS384 | HS512 | RS256 | RS384 | RS512 | PS256 | PS384 | PS512 | ES256 | ES384 | ES512 | EdDSA.

JWT Authentication Helper
This helper provides functions for encoding, decoding, signing, and verifying JSON Web Tokens (JWTs). JWTs are commonly used for authentication and authorization purposes in web applications. This helper offers robust JWT functionality with support for various cryptographic algorithms.

Import
To use this helper, you can import it as follows:


import { decode, sign, verify } from 'hono/jwt'
INFO

JWT Middleware also import the jwt function from the hono/jwt.

sign()
This function generates a JWT token by encoding a payload and signing it using the specified algorithm and secret.


sign(
  payload: unknown,
  secret: string,
  alg?: 'HS256';

): Promise<string>;
Example

import { sign } from 'hono/jwt'

const payload = {
  sub: 'user123',
  role: 'admin',
  exp: Math.floor(Date.now() / 1000) + 60 * 5, // Token expires in 5 minutes
}
const secret = 'mySecretKey'
const token = await sign(payload, secret)
Options

required payload: unknown
The JWT payload to be signed. You can include other claims like in Payload Validation.

required secret: string
The secret key used for JWT verification or signing.

optional alg: AlgorithmTypes
The algorithm used for JWT signing or verification. The default is HS256.

verify()
This function checks if a JWT token is genuine and still valid. It ensures the token hasn't been altered and checks validity only if you added Payload Validation.


verify(
  token: string,
  secret: string,
  alg?: 'HS256';
): Promise<any>;
Example

import { verify } from 'hono/jwt'

const tokenToVerify = 'token'
const secretKey = 'mySecretKey'

const decodedPayload = await verify(tokenToVerify, secretKey)
console.log(decodedPayload)
Options

required token: string
The JWT token to be verified.

required secret: string
The secret key used for JWT verification or signing.

optional alg: AlgorithmTypes
The algorithm used for JWT signing or verification. The default is HS256.

decode()
This function decodes a JWT token without performing signature verification. It extracts and returns the header and payload from the token.


decode(token: string): { header: any; payload: any };
Example

import { decode } from 'hono/jwt'

// Decode the JWT token
const tokenToDecode =
  'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAidXNlcjEyMyIsICJyb2xlIjogImFkbWluIn0.JxUwx6Ua1B0D1B0FtCrj72ok5cm1Pkmr_hL82sd7ELA'

const { header, payload } = decode(tokenToDecode)

console.log('Decoded Header:', header)
console.log('Decoded Payload:', payload)
Options

required token: string
The JWT token to be decoded.

The decode function allows you to inspect the header and payload of a JWT token without performing verification. This can be useful for debugging or extracting information from JWT tokens.

Payload Validation
When verifying a JWT token, the following payload validations are performed:

exp: The token is checked to ensure it has not expired.
nbf: The token is checked to ensure it is not being used before a specified time.
iat: The token is checked to ensure it is not issued in the future.
Please ensure that your JWT payload includes these fields, as an object, if you intend to perform these checks during verification.

Custom Error Types
The module also defines custom error types to handle JWT-related errors.

JwtAlgorithmNotImplemented: Indicates that the requested JWT algorithm is not implemented.
JwtTokenInvalid: Indicates that the JWT token is invalid.
JwtTokenNotBefore: Indicates that the token is being used before its valid date.
JwtTokenExpired: Indicates that the token has expired.
JwtTokenIssuedAt: Indicates that the "iat" claim in the token is incorrect.
JwtTokenSignatureMismatched: Indicates a signature mismatch in the token.
Supported AlgorithmTypes
The module supports the following JWT cryptographic algorithms:

HS256: HMAC using SHA-256
HS384: HMAC using SHA-384
HS512: HMAC using SHA-512
RS256: RSASSA-PKCS1-v1_5 using SHA-256
RS384: RSASSA-PKCS1-v1_5 using SHA-384
RS512: RSASSA-PKCS1-v1_5 using SHA-512
PS256: RSASSA-PSS using SHA-256 and MGF1 with SHA-256
PS384: RSASSA-PSS using SHA-386 and MGF1 with SHA-386
PS512: RSASSA-PSS using SHA-512 and MGF1 with SHA-512
ES256: ECDSA using P-256 and SHA-256
ES384: ECDSA using P-384 and SHA-384
ES512: ECDSA using P-521 and SHA-512
EdDSA: EdDSA using Ed25519