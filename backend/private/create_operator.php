<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/auth.php';

$name = trim($argv[1] ?? '');
$email = strtolower(trim($argv[2] ?? ''));
$password = getenv('PARCEL_OPERATOR_PASSWORD') ?: '';

if ($name === '' || strlen($name) > 100 || preg_match('//u', $name) !== 1 ||
    !validEmail($email) || !validPassword($password)) {
    fwrite(STDERR, "Usage: set PARCEL_OPERATOR_PASSWORD (8–72 bytes), then run php create_operator.php \"Name\" email\n");
    exit(1);
}

try {
    if (!createUser(database(), $name, $email, $password, OPERATOR)) {
        fwrite(STDERR, "Email already exists. No account or role was changed.\n");
        exit(1);
    }
    echo "Parcel Operator account created.\n";
} catch (Throwable $error) {
    fwrite(STDERR, 'Setup failed: ' . $error->getMessage() . PHP_EOL);
    exit(1);
}

