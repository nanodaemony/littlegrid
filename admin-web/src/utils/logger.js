/**
 * 统一日志 API
 * 支持模块、TraceId、结构化格式
 */

const SENSITIVE_FIELDS = ['password', 'pwd', 'token', 'accessToken', 'refreshToken', 'secret', 'apiKey', 'creditCard', 'Authorization']
const MASK_VALUE = '******'

/**
 * 格式化时间戳
 */
function formatTime() {
  const now = new Date()
  const hours = now.getHours().toString().padStart(2, '0')
  const minutes = now.getMinutes().toString().padStart(2, '0')
  const seconds = now.getSeconds().toString().padStart(2, '0')
  return `${hours}:${minutes}:${seconds}`
}

/**
 * 脱敏 JSON 数据
 */
function maskSensitiveData(data) {
  if (!data) return data
  if (typeof data !== 'object') return data

  const masked = Array.isArray(data) ? [...data] : { ...data }

  if (Array.isArray(masked)) {
    return masked.map(item => maskSensitiveData(item))
  }

  SENSITIVE_FIELDS.forEach(field => {
    if (masked[field] !== undefined) {
      masked[field] = MASK_VALUE
    }
  })

  // 递归处理嵌套对象
  Object.keys(masked).forEach(key => {
    if (typeof masked[key] === 'object' && masked[key] !== null) {
      masked[key] = maskSensitiveData(masked[key])
    }
  })

  return masked
}

/**
 * 获取当前 TraceId
 */
function getTraceId() {
  return localStorage.getItem('currentTraceId') || 'no-trace'
}

/**
 * 统一日志对象
 */
const Logger = {
  debug(module, message, data = null) {
    const traceId = getTraceId()
    const logMsg = `[${formatTime()}] DEBUG [${module}] [${traceId}] ${message}`
    if (data) {
      console.debug(logMsg, maskSensitiveData(data))
    } else {
      console.debug(logMsg)
    }
  },

  info(module, message, data = null) {
    const traceId = getTraceId()
    const logMsg = `[${formatTime()}] INFO [${module}] [${traceId}] ${message}`
    if (data) {
      console.info(logMsg, maskSensitiveData(data))
    } else {
      console.info(logMsg)
    }
  },

  warn(module, message, data = null) {
    const traceId = getTraceId()
    const logMsg = `[${formatTime()}] WARN [${module}] [${traceId}] ${message}`
    if (data) {
      console.warn(logMsg, maskSensitiveData(data))
    } else {
      console.warn(logMsg)
    }
  },

  error(module, message, error = null) {
    const traceId = getTraceId()
    const logMsg = `[${formatTime()}] ERROR [${module}] [${traceId}] ${message}`
    if (error) {
      console.error(logMsg, error)
    } else {
      console.error(logMsg)
    }
  },

  /**
   * 生成 TraceId
   */
  generateTraceId() {
    const timestamp = Date.now()
    const random = (timestamp % 1000000).toString().padStart(6, '0')
    const prefix = (timestamp % 100).toString().padStart(2, '0')
    return `${prefix}${random}`
  },

  /**
   * 设置 TraceId
   */
  setTraceId(traceId) {
    localStorage.setItem('currentTraceId', traceId)
  },

  /**
   * 清除 TraceId
   */
  clearTraceId() {
    localStorage.removeItem('currentTraceId')
  }
}

export default Logger