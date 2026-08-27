const fs = require('fs');
const { execSync } = require('child_process');
const p = 'ios/Runner.xcodeproj/project.pbxproj';
let c = fs.readFileSync(p, 'utf8');

// 1. Automatic -> Manual
c = c.replace(/CODE_SIGN_STYLE = Automatic;/g, 'CODE_SIGN_STYLE = Manual;');
// 2. iPhone Developer (development cert) -> Apple Distribution (production cert)
c = c.replace(/"iPhone Developer"/g, '"Apple Distribution"');

// 3. 动态解析 Codemagic 注入的 provisioning profile 真实名称（按 bundle id 匹配）。
//    Windows 本地无 security 命令会走 fallback，Codemagic macOS 上会真正解码匹配。
let profileName = 'moyuquan-appstore';
try {
  const dir = (process.env.HOME || '') + '/Library/MobileDevice/Provisioning Profiles/';
  if (fs.existsSync(dir)) {
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.mobileprovision'));
    for (const f of files) {
      try {
        const xml = execSync('security cms -D -i "' + dir + f + '" 2>/dev/null').toString();
        const nameM = xml.match(/<key>Name<\/key>\s*<string>([^<]+)<\/string>/);
        const appM = xml.match(/<key>application-identifier<\/key>\s*<string>([^<]+)<\/string>/);
        if (nameM && appM && appM[1].includes('com.fishing.fishingApp')) {
          profileName = nameM[1];
          break;
        }
      } catch (e) { /* 跳过无法解码的 profile */ }
    }
  }
} catch (e) {
  console.log('profile scan fallback:', e.message);
}
console.log('resolved provisioning profile name:', profileName);

// 4. 注入 team + profile specifier 到 pbxproj（archive 阶段用）
c = c.replace(/CODE_SIGN_STYLE = Manual;/g,
  'CODE_SIGN_STYLE = Manual;\n\t\t\t\tDEVELOPMENT_TEAM = 25UKD3GY5R;\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = ' + profileName + ';');

// 5. 同步更新 ExportOptions.plist（export 阶段用），保证两处 profile 名一致
const ep = 'ios/ExportOptions.plist';
if (fs.existsSync(ep)) {
  let e = fs.readFileSync(ep, 'utf8');
  e = e.replace(/(<key>com\.fishing\.fishingApp<\/key>\s*<string>)[^<]+(<\/string>)/, '$1' + profileName + '$2');
  fs.writeFileSync(ep, e);
  console.log('synced ExportOptions.plist profile name');
}

fs.writeFileSync(p, c);
console.log('patched project.pbxproj: manual + team 25UKD3GY5R + profile ' + profileName);
