### Owner account

The install creates the Rowflare owner account with the email address of the YunoHost user you chose and the password you entered. Rowflare has its own accounts: it is not connected to the YunoHost LDAP or SSO, so other people join through an invite sent from Rowflare (workspace settings, Members).

### Dedicated domain

Rowflare must be installed at the root of a domain, for example `rowflare.example.com`. Installing in a sub-path such as `example.com/rowflare` is not supported by the app.

### Permissions

- `main` (the tile) controls who can open the web app. Even when it is public, only people with a Rowflare account can see bases.
- `api` covers `/api` and `/mcp` and is public by default, because the REST API, webhooks, public forms and the MCP server authenticate with Rowflare's own tokens. If you make it private, API clients, webhooks and form submissions from outside the YunoHost portal stop working.
- Public form links (`/form/...`) are web pages, so they follow the `main` permission: keep `main` public if people without a YunoHost account must fill in forms.

### Data and backups

Bases, accounts and attachments are stored in `__DATA_DIR__`. YunoHost backups include this directory. The copy is taken while Rowflare is running; for a fully consistent copy, stop the app first:

```bash
systemctl stop __APP__
yunohost backup create --apps __APP__
systemctl start __APP__
```

Rowflare can also export each base as CSV or JSON from the app.

### Account emails

No mail server is configured, so Rowflare does not send email verification or password reset links: the "Forgot password?" page asks people to contact the administrator. Automations can still send email through the SMTP or Resend settings each workspace owner saves in Rowflare.

To enable account emails, or to change any other setting from the [upstream self-hosting documentation](https://rowflare.com/docs/self-hosting/), put the variables in `__DATA_DIR__/custom.env`. This file is read on top of the generated configuration, is kept on upgrades and is included in backups:

```bash
cat > __DATA_DIR__/custom.env <<'END'
MAIL_PROVIDER=smtp
MAIL_FROM=rowflare@example.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=rowflare@example.com
SMTP_PASSWORD=your-password
END
chown root:root __DATA_DIR__/custom.env
chmod 600 __DATA_DIR__/custom.env
systemctl restart __APP__
```

### Upgrades

Rowflare is built from source during install and upgrade. This needs about 2 GB of RAM, network access to the npm registry and a few minutes.
