package domain

import (
	"fmt"
	"strings"
	"unicode"
)

// MakeSlug 从 name 生成 URL 友好的 slug。
// ASCII 字符：小写化，空格/下划线转为连字符，去除非字母数字。
// 中文字符：回退为 "slug-{prefix}" 格式，确保唯一性。
func MakeSlug(name, prefix string) string {
	hasNonASCII := false
	for _, r := range name {
		if r > unicode.MaxASCII {
			hasNonASCII = true
			break
		}
	}
	if hasNonASCII {
		return fmt.Sprintf("slug-%s", prefix)
	}

	var b strings.Builder
	for _, r := range strings.ToLower(name) {
		if r == ' ' || r == '_' || r == '-' {
			if b.Len() > 0 && b.String()[b.Len()-1] != '-' {
				b.WriteRune('-')
			}
		} else if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
		}
	}
	slug := strings.Trim(b.String(), "-")
	if slug == "" {
		return fmt.Sprintf("slug-%s", prefix)
	}
	return slug
}
