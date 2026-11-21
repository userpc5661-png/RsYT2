# Feature coverage and user test notes

The source is original RS Insta code. The reference binary has not been copied into this repository.

| Feature | Implementation | Device verification |
| --- | --- | --- |
| Hide Story Seen | One opt-in method hook | Not tested |
| Hide Direct Read Receipt | One opt-in method hook | Not tested |
| Screenshot Blocking Bypass | One opt-in method hook | Not tested |
| Direct HTTPS media URL download/share | URLSession + share sheet | Not tested |
| RS floating launcher | UIKit | Not tested |
| Three-finger tap launcher | UIKit gesture | Not tested |
| NSUserDefaults preferences | Implemented | Not tested |
| Other 20 menu entries | Not implemented | Not applicable |

A passed Actions compilation indicates only that the code compiles into an iOS ARM64 Mach-O dylib. It does not verify injection, signature, or compatibility. Runtime hooking requires a compatible injection environment with a provider of MSHookMessageEx. External method signatures are not dynamically verified; test in a non-production setup.

When reporting a failure include Instagram version, iOS version, injection method, option, expected and actual behavior, and any crash log without account or session secrets.

Do not commit the proprietary reference binary or personal tokens to this public repository.
