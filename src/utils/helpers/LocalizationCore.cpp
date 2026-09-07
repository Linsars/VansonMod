#include "LocalizationCore.hpp"

LocalizationCore &LocalizationCore::getInstance() {
  static LocalizationCore instance;
  return instance;
}

LocalizationCore::LocalizationCore() : _userLang("Auto") {
  initLanguages();
}

void LocalizationCore::initLanguages() {
  
}

std::string LocalizationCore::getEffectiveLanguage() const {
  // 仅保留中文与英文，其余语言表已裁撤
  if (_userLang == "en") return "en";
  return "cn";
}

std::string LocalizationCore::get(const std::string &key) {
  std::string lang = getEffectiveLanguage();
  
  auto langIt = _allStrings.find(lang);
  if (langIt != _allStrings.end()) {
    auto keyIt = langIt->second.find(key);
    if (keyIt != langIt->second.end() && !keyIt->second.empty()) {
      return keyIt->second;
    }
  }
  
  if (lang != "cn") {
    langIt = _allStrings.find("cn");
    if (langIt != _allStrings.end()) {
      auto keyIt = langIt->second.find(key);
      if (keyIt != langIt->second.end() && !keyIt->second.empty()) {
        return keyIt->second;
      }
    }
  }
  
  return key;
}

void LocalizationCore::setLanguage(const std::string &lang) {
  _userLang = lang;
}

std::string LocalizationCore::getCurrentLanguage() const {
  return _userLang;
}

bool LocalizationCore::isChinese() const {
  std::string eff = getEffectiveLanguage();
  return (eff == "cn" || eff == "tw");
}

void LocalizationCore::registerTranslations(const std::string &langCode,
                                            const std::map<std::string, std::string> &translations) {
  _allStrings[langCode] = translations;
}
