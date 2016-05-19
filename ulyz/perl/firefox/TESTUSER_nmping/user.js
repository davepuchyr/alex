// TESTUSER_nmping http://duo.anoxymous.com:3128 Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; [xSP_2:74c4cfd6de98ee37d69889cc15c9d7f2_158]; 796801903)
// important
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "http://dual.anoxymous.com/x/env?site=sandbox.ebay.com&whoami=TESTUSER_nmping");
user_pref("general.useragent.override", "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; [xSP_2:74c4cfd6de98ee37d69889cc15c9d7f2_158]; 796801903)");
user_pref("network.proxy.type", 1);
user_pref("network.proxy.ftp", "duo.anoxymous.com");
user_pref("network.proxy.ftp_port", 3128);
user_pref("network.proxy.gopher", "duo.anoxymous.com");
user_pref("network.proxy.gopher_port", 3128);
user_pref("network.proxy.http", "duo.anoxymous.com");
user_pref("network.proxy.http_port", 3128);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "duo.anoxymous.com");
user_pref("network.proxy.socks_port", 3128);
user_pref("network.proxy.ssl", "duo.anoxymous.com");
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
