/**
 * Zod validation middleware factory.
 * Validates req.body against the given Zod schema.
 * On success, replaces req.body with the parsed (typed) data.
 * On failure, returns 400 with per-field error details.
 */

'use strict';

/**
 * @param {import('zod').ZodSchema} schema
 * @returns {import('express').RequestHandler}
 */
function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request data.',
          fields: result.error.flatten().fieldErrors,
        },
      });
    }

    req.body = result.data;
    next();
  };
}

module.exports = { validate };
