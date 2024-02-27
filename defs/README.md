# Manifest and Playbook Detail

## Playbooks

Basic support for YAML playbooks was added in Windex v0.1.1.

The parser is being adapted to support more and more functions as time goes on. The currently supported schema is roughly demonstrated below...

```yaml
-
  name: Disable Windows Feeds
  actions:
  - regset: HKLM\Software\Policies\Microsoft\Windows\Windows Feeds
    subkey: EnableFeeds
    value: dword:00000000

-
  name: Hide search bar on taskbar (reversable by user)
  actions:
  - regset: <USERS>\Software\Microsoft\Windows\CurrentVersion\Search
    subkey: SearchBoxTaskbarMode
    value: dword:00000000
  - pwsh: Get-Process Explorer | Stop-Process

-
  name: "Disable automatic Game Bar enablement"
  actions:
  - regset: HKLM\Software\Microsoft\GameBar
    subkey:
      - AllowAutoGameMode
      - AutoGameModeEnabled
    value: dword:00000000
```

Note that each segment is preceeded by a lone `-`.

The `name` element is required and will sometimes be printed to the user.

The `actions` block can contain a list of however many actions of however many supported types you wish. (note how the second tweak has one `regset` and one `pwsh`)

### Tweak Actions

**`regset`** can be used to set or create registry items. One or many `subkey` values can be included here. Each of these subkeys will be set to `value`, which is the key type and raw value deliminated by a colon (such as `dword:00000001`).

Special here is the `<USERS>` keyword, as seen in the second tweak. When the `<USERS>` keyword is used in place of a hive, Windex will apply the tweak to the hive of all users loaded into HKEY_USERS (those that match SID `S-1-5-21-[...]`), and to the NTUSER.dat hives of each user found in `%SystemDrive%\Users` that is *not* currently loaded into HKEY_USERS. This can be useful in situations where you want users to be able to revert the tweak, or in situations where HKEY_LOCAL_MACHINE (etc) is ignored.

**`pwsh`** can be used to run arbitrary powershell commands and script blocks. In the case of the second tweak, it's being used to restart the Explorer process, refreshing the now-changed taskbar for the user. Script blocks can be included here following standard yaml syntax (pipe-prefaced text).

**`svcset`** action can be used to interact with system services. Currently only accepts value `disabled`. Requires element `service` to also be set, accepting raw service names. Can be one or many services.

### Additional Attributes

Tweaks with the **`category`** attribute will be excluded from the auto-apply module. `Advanced` is only currently implemented category.