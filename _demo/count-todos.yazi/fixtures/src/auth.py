def login(user, password):
    # @todo validate password strength
    return check_credentials(user, password)


def logout(session):
    # @todo invalidate session token server-side
    session.clear()
