from pathlib import Path
source = Path("src/RSInsta.m").read_text()
assert "RSInstaStartup" in source
assert "RSInstaMenuController" in source
assert "MSHookMessageEx" in source
assert "rsDownloadURL" in source
assert "numberOfTouchesRequired = 3" in source
assert "com.burbn.instagram" in source
features = ["ghost_story_seen","hide_direct_read","screenshot_bypass","deleted_messages","view_once","story_download","reels_download","photo_download","profile_analyzer","profile_photo","comment_search","voice_changer","call_recording","gemini_ai","auto_reply","app_icons","language","liquid_glass","pip","reels_blocker","close_friends","device_identity","internal_settings"]
for feature in features:
    assert ('@"key":@"' + feature + '"') in source, feature
assert source.count('@"hook":@YES') == 3
print("PASS: %d menu entries, three experimental hooks, one media-URL utility" % len(features))
