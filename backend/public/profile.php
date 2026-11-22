<?php

declare(strict_types=1);

require_once __DIR__ . '/../private/auth.php';

endpoint('GET', function (): void {
    $tokenHash = requestTokenHash();
    $query = database()->prepare('SELECT users.id, name, email, role FROM users
        JOIN sessions ON sessions.user_id = users.id
        WHERE token_hash = :token AND expires_at > :now');
    $query->execute([':token' => $tokenHash, ':now' => time()]);
    $user = $query->fetch();
    if ($user === false) {
        failure(401, 'Your session has ended. Please sign in.');
    }
    respond(200, ['success' => true, 'user' => $user]);
});

