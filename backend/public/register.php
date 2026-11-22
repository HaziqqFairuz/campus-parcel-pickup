<?php

declare(strict_types=1);

require_once __DIR__ . '/../private/auth.php';

endpoint('POST', function (): void {
    $name = trim(field('name'));
    $email = strtolower(trim(field('email')));
    $password = field('password');

    if ($name === '' || strlen($name) > 100 || preg_match('//u', $name) !== 1) {
        failure(422, 'Enter a name of up to 100 bytes.');
    }
    if (!validEmail($email)) {
        failure(422, 'Enter a valid email address.');
    }
    if (!validPassword($password)) {
        failure(422, 'Use a password of 8 to 72 bytes.');
    }
    if ($password !== field('confirm_password')) {
        failure(422, 'Passwords must match.');
    }
    if (!createUser(database(), $name, $email, $password, RECIPIENT)) {
        failure(409, 'An account already exists for this email.');
    }
    respond(201, ['success' => true, 'message' => 'Account created. You can now sign in.']);
});

