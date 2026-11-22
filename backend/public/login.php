<?php

declare(strict_types=1);

require_once __DIR__ . '/../private/auth.php';

endpoint('POST', function (): void {
    $email = strtolower(trim(field('email')));
    $password = field('password');
    if (!validEmail($email) || !validPassword($password)) {
        failure(401, 'Email or password is incorrect.');
    }

    $db = database();
    $query = $db->prepare('SELECT id, password_hash FROM users WHERE email = :email');
    $query->execute([':email' => $email]);
    $user = $query->fetch();
    // Run bcrypt even when the email does not exist.
    $hash = $user['password_hash'] ?? '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';
    if (!password_verify($password, $hash) || $user === false) {
        failure(401, 'Email or password is incorrect.');
    }

    $now = time();
    $db->prepare('DELETE FROM sessions WHERE expires_at <= :now')->execute([':now' => $now]);
    $token = bin2hex(random_bytes(32));
    $db->prepare('INSERT INTO sessions (token_hash, user_id, expires_at)
        VALUES (:token, :user, :expiry)')->execute([
        ':token' => hash('sha256', $token),
        ':user' => $user['id'],
        ':expiry' => $now + SESSION_SECONDS,
    ]);
    respond(200, ['success' => true, 'token' => $token]);
});

