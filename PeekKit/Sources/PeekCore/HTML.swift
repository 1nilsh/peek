extension String {
    public var htmlEscaped: String {
        var out = ""
        out.reserveCapacity(utf8.count)
        for c in self {
            switch c {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(c)
            }
        }
        return out
    }
}
