const fs = require('fs');
const p = 'ios/Runner.xcodeproj/project.pbxproj';
let c = fs.readFileSync(p, 'utf8');

// 1. Automatic -> Manual
c = c.replace(/CODE_SIGN_STYLE = Automatic;/g, 'CODE_SIGN_STYLE = Manual;');
// 2. iPhone Developer (development cert) -> Apple Distribution (production cert)
c = c.replace(/"iPhone Developer"/g, '"Apple Distribution"');
// 3. 每个 Manual 块后注入 team + profile specifier（archive 阶段用）
c = c.replace(/CODE_SIGN_STYLE = Manual;/g,
  'CODE_SIGN_STYLE = Manual;\n\t\t\t\tDEVELOPMENT_TEAM = 25UKD3GY5R;\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = moyuquan-appstore;');

fs.writeFileSync(p, c);
console.log('patched project.pbxproj: manual signing + team 25UKD3GY5R + profile moyuquan-appstore');
