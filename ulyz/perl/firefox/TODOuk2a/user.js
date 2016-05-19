// TODOuk2a http://uk2a.anoxymous.com:3128 Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.2.11) Gecko/20101012 Firefox/3.6.11
// important
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "http://dual.anoxymous.com/x/env?site=ebay.co.uk&whoami=TODOuk2a");
user_pref("general.useragent.override", "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-GB; rv:1.9.2.11) Gecko/20101012 Firefox/3.6.11");
user_pref("network.proxy.type", 1);
user_pref("network.proxy.ftp", "uk2a.anoxymous.com");
user_pref("network.proxy.ftp_port", 3128);
user_pref("network.proxy.gopher", "uk2a.anoxymous.com");
user_pref("network.proxy.gopher_port", 3128);
user_pref("network.proxy.http", "uk2a.anoxymous.com");
user_pref("network.proxy.http_port", 3128);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "uk2a.anoxymous.com");
user_pref("network.proxy.socks_port", 3128);
user_pref("network.proxy.ssl", "uk2a.anoxymous.com");
user_pref("network.proxy.ssl_port", 3128);
// convenience
user_pref("permissions.default.image", 2); // block ALL images; use "3" to block 3rd party images
user_pref("security.enable_java", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("layout.spellcheckDefault", 0);
user_pref("general.warnOnAboutConfig", false);
user_pref("browser.backspace_action", 0);
user_pref("security.warn_viewing_mixed", false);
user_pref("accessibility.typeaheadfind", true);
user_pref("general.smoothScroll", false);
// http://www.mozilla.org/unix/customizing.html#prefs
// Image animation mode: normal, once, none.
// This pref now has UI under Privacy & Security->Images.
user_pref("image.animation_mode", "none");
// Middle mouse prefs: true by default on Unix, false on other platforms.
user_pref("middlemouse.paste", true);
user_pref("middlemouse.openNewWindow", true);
user_pref("middlemouse.contentLoadURL", false);
user_pref("middlemouse.scrollbarPosition", false);
