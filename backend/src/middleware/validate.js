/**
 * Zod validation middleware factory.
 * Validates req.body or req.query against the given Zod schema.
 * On success, replaces the validated object with the parsed (coerced) data.
 * On failure, returns 400 with per-field error details.
 */

'use strict';

/**
 * @param {import('zod').ZodSchema} schema
 * @param {'body'|'query'} [source='body'] - Which request object to validate
 * @returns {import('express').RequestHandler}
 */
function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);

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

    if (source === 'query') {
      Object.keys(req.query).forEach(k => delete req.query[k]);
      Object.assign(req.query, result.data);
    } else {
      req[source] = result.data;
    }
    next();
  };
}

module.exports = { validate };
