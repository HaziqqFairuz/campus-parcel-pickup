<?php

declare(strict_types=1);

require_once __DIR__ . '/../private/auth.php';

endpoint('POST', function (): void {
    $tokenHash = requestTokenHash();
    // The same token can safely retry logout after a lost response.
    database()->prepare('DELETE FROM sessions WHERE token_hash = :token')
        ->execute([':token' => $tokenHash]);
    respond(200, ['success' => true, 'message' => 'Signed out.']);
});

