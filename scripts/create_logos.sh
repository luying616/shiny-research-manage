#!/bin/bash

# ==================== Logo生成脚本 ====================
# 功能：为系统创建简单的SVG占位符logo
# 使用方法：bash create_logos.sh
# ===================================================

echo "正在生成Logo占位符..."

# 创建主Logo (SVG格式)
cat > www/logo.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="50" viewBox="0 0 200 50">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- 背景 -->
  <rect width="200" height="50" rx="5" fill="url(#grad1)"/>
  
  <!-- 文字 -->
  <text x="100" y="30" font-family="Arial, sans-serif" font-size="18" font-weight="bold" 
        text-anchor="middle" fill="white">科研管理系统</text>
</svg>
EOF

echo "✓ 主Logo已创建: www/logo.svg"

# 创建浏览器标签页图标 (SVG格式)
cat > www/logo_tab.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- 背景圆形 -->
  <circle cx="32" cy="32" r="30" fill="url(#grad2)"/>
  
  <!-- 科研图标 - 显微镜简化版 -->
  <g fill="white">
    <rect x="28" y="18" width="8" height="4" rx="1"/>
    <rect x="30" y="22" width="4" height="16"/>
    <rect x="26" y="38" width="12" height="3" rx="1"/>
    <circle cx="32" cy="28" r="5" fill="none" stroke="white" stroke-width="2"/>
  </g>
</svg>
EOF

echo "✓ 标签页Logo已创建: www/logo_tab.svg"

# 说明如何使用ImageMagick转换为PNG（如果可用）
if command -v convert &> /dev/null; then
    echo ""
    echo "检测到ImageMagick，正在转换为PNG格式..."
    
    convert www/logo.svg www/logo.png
    echo "✓ 已生成: www/logo.png"
    
    convert www/logo_tab.svg -resize 64x64 www/logo_tab.png
    echo "✓ 已生成: www/logo_tab.png"
    
    echo ""
    echo "PNG文件已生成！"
else
    echo ""
    echo "注意：未检测到ImageMagick。"
    echo "SVG文件已创建，但需要将它们转换为PNG格式。"
    echo ""
    echo "安装ImageMagick："
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo ""
    echo "然后运行："
    echo "  convert www/logo.svg www/logo.png"
    echo "  convert www/logo_tab.svg -resize 64x64 www/logo_tab.png"
fi

echo ""
echo "================================================"
echo "Logo占位符生成完成！"
echo ""
echo "生成的文件："
echo "  - www/logo.svg (主Logo)"
echo "  - www/logo_tab.svg (标签页图标)"
if [ -f "www/logo.png" ]; then
    echo "  - www/logo.png (主Logo PNG版本)"
    echo "  - www/logo_tab.png (标签页图标 PNG版本)"
fi
echo ""
echo "提示：这些是简单的占位符，建议使用专业设计的Logo替换。"
echo "================================================"
