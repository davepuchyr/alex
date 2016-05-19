// caut_caro http://de2.anoxymous.com:3128 Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.9) Gecko/20100824 (WEB.DE/1.6.2) Firefox/3.6.9 ( .NET CLR 3.5.30729)
// important
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "http://dual.anoxymous.com/x/env?site=ebay.de&whoami=caut_caro");
user_pref("general.useragent.override", "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.9) Gecko/20100824 (WEB.DE/1.6.2) Firefox/3.6.9 ( .NET CLR 3.5.30729)");
user_pref("network.proxy.type", 1);
user_pref("network.proxy.ftp", "de2.anoxymous.com");
user_pref("network.proxy.ftp_port", 3128);
user_pref("network.proxy.gopher", "de2.anoxymous.com");
user_pref("network.proxy.gopher_port", 3128);
user_pref("network.proxy.http", "de2.anoxymous.com");
user_pref("network.proxy.http_port", 3128);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "de2.anoxymous.com");
user_pref("network.proxy.socks_port", 3128);
user_pref("network.proxy.ssl", "de2.anoxymous.com");
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
