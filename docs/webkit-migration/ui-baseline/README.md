# Original UI fixture baseline

Downloaded from `ieynec-ui-checks` artifact of original run
https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/40082560152
at source `14452d327bf08c6222567adfd308701cf9e16e15`.

These are synthetic Simulator fixtures, NOT the owner's private screenshots and
NOT full Gecko browsing E2E tests. No new engine is rendered in these images.
The artifact's `*-on-screen.png` files contain JPEG bytes despite their names;
the original files are retained without conversion.

- `addressbar-on-screen.png`: real bottom address-bar fixture; host page is synthetic.
- `private-on-screen.png`: private homepage fixture.
- `home-on-screen.png`: homepage fixture with engine/store/section doubles.
- `groups-on-screen.png`: group/navigation fixture.
- `chrome-scroll-states.png`: component exports at five toolbar translation states,
  yellow synthetic page canvas, not real website/Gecko compositor output.

Compare the same fixtures and physical viewport/toolchain for future UI changes.
Pixel identity does not prove gestures, website compatibility, keyboard, video,
or private data isolation. Full all-pages/device interaction baseline remains
pending; see `../DEVICE-TESTS.zh-CN.md`.
