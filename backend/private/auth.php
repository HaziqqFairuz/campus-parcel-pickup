<?php

declare(strict_types=1);

const SESSION_SECONDS = 86400;
const RECIPIENT = 'recipient';
const OPERATOR = 'parcel_operator';

function database(): PDO
{
    $path = getenv('PARCEL_DB_PATH') ?: __DIR__ . '/parcel.sqlite';
    $directory = realpath(dirname($path));
    $root = PHP_SAPI === 'cli' ? false : realpath($_SERVER['DOCUMENT_ROOT'] ?? '');

    if ($directory === false || ($root !== false && insideDirectory($directory, $root))) {
        throw new RuntimeException('Configure the SQLite file outside the public document root.');
    }
    if (is_link($path)) {
        throw new RuntimeException('The SQLite path must not be a symbolic link.');
    }

    $db = new PDO('sqlite:' . $directory . DIRECTORY_SEPARATOR . basename($path));
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $db->exec('PRAGMA foreign_keys = ON');
    $db->exec('PRAGMA busy_timeout = 5000');
    $db->exec("CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'recipient' CHECK (role IN ('recipient', 'parcel_operator')),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS sessions (
        token_hash TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
        expires_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS sessions_expiry ON sessions (expires_at);");

    return $db;
}

function insideDirectory(string $path, string $root): bool
{
    $path = str_replace('\\', '/', $path);
    $root = rtrim(str_replace('\\', '/', $root), '/');
    if (PHP_OS_FAMILY === 'Windows') {
        $path = strtolower($path);
        $root = strtolower($root);
    }
    return $path === $root || str_starts_with($path, $root . '/');
}

function respond(int $status, array $data): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($data, JSON_THROW_ON_ERROR);
    exit;
}

function failure(int $status, string $message): void
{
    respond($status, ['success' => false, 'message' => $message]);
}

function endpoint(string $method, callable $handler): void
{
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    header('Vary: Origin');
    if (in_array($origin, ['http://localhost:5200', 'http://127.0.0.1:5200'], true)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS' &&
            ($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'] ?? '') === $method) {
            header('Access-Control-Allow-Methods: ' . $method);
            header('Access-Control-Allow-Headers: Authorization, Content-Type');
            http_response_code(204);
            exit;
        }
    }

    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        header('Allow: ' . $method);
        failure(405, 'This request method is not supported.');
    }

    try {
        $handler();
    } catch (Throwable $error) {
        error_log('Campus Parcel Pickup: ' . $error->getMessage());
        failure(500, 'The service is temporarily unavailable. Try again.');
    }
}

function field(string $key): string
{
    $value = $_POST[$key] ?? '';
    return is_string($value) ? $value : '';
}

function validEmail(string $email): bool
{
    return strlen($email) <= 254 && filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function validPassword(string $password): bool
{
    // Bcrypt accepts up to 72 bytes and rejects null bytes.
    return strlen($password) >= 8 && strlen($password) <= 72 && !str_contains($password, "\0");
}

function createUser(PDO $db, string $name, string $email, string $password, string $role): bool
{
    $query = $db->prepare('INSERT INTO users (name, email, password_hash, role)
        VALUES (:name, :email, :password, :role) ON CONFLICT(email) DO NOTHING');
    $query->execute([
        ':name' => $name,
        ':email' => $email,
        ':password' => password_hash($password, PASSWORD_BCRYPT),
        ':role' => $role,
    ]);
    return $query->rowCount() === 1;
}

function requestTokenHash(): string
{
    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (preg_match('/^Bearer ([0-9a-f]{64})$/iD', $authorization, $matches) !== 1) {
        failure(401, 'Please sign in to continue.');
    }
    return hash('sha256', $matches[1]);
}

