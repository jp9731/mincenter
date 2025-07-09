#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 사용 중인 아이콘들을 추출하는 함수
function extractUsedIcons() {
  const usedIcons = new Set();
  
  // Svelte 파일들을 재귀적으로 찾기
  function findSvelteFiles(dir) {
    const files = [];
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
        files.push(...findSvelteFiles(fullPath));
      } else if (item.endsWith('.svelte')) {
        files.push(fullPath);
      }
    }
    
    return files;
  }
  
  const svelteFiles = findSvelteFiles('frontends');
  
  svelteFiles.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    const importMatches = content.match(/import\s*{([^}]+)}\s*from\s*['"]lucide-svelte['"]/g);
    
    if (importMatches) {
      importMatches.forEach(match => {
        const iconMatches = match.match(/import\s*{([^}]+)}\s*from\s*['"]lucide-svelte['"]/);
        if (iconMatches) {
          const icons = iconMatches[1].split(',').map(icon => {
            const trimmed = icon.trim();
            // as 별칭 처리
            if (trimmed.includes(' as ')) {
              return trimmed.split(' as ')[0].trim();
            }
            return trimmed;
          });
          icons.forEach(icon => usedIcons.add(icon));
        }
      });
    }
  });
  
  return Array.from(usedIcons);
}

// 사용 중인 아이콘들 출력
const usedIcons = extractUsedIcons();
console.log('사용 중인 lucide-svelte 아이콘들:');
console.log(usedIcons.sort());
console.log(`\n총 ${usedIcons.length}개의 아이콘이 사용되고 있습니다.`);

// 번들 크기 분석
console.log('\n=== 번들 최적화 권장사항 ===');
console.log('1. Tree shaking이 활성화되어 있으므로 사용하지 않는 아이콘들은 자동으로 제거됩니다.');
console.log('2. vite.config.ts에서 lucide-svelte를 manualChunks에서 제거하여 개별 아이콘 단위로 번들링됩니다.');
console.log('3. terser 압축으로 번들 크기를 더욱 줄일 수 있습니다.'); 