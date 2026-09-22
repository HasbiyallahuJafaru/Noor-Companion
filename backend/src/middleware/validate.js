/**
 * Zod validation middleware factory.
 * Validates req.body, req.query, or req.params against the given Zod schema.
 * On success, merges the parsed (coerced) data into the request object.
 * On failure, returns 400 with per-field error details.
 */

'use strict';

/**
 * @param {import('zod').ZodSchema} schema
 * @param {'body'|'query'|'params'} [source='body'] - Which request object to validate
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

    // Express 5 defines query/params as getter-only properties — mutate the
    // object in place instead of reassigning it.
    Object.assign(req[source], result.data);
    next();
  };
}

module.exports = { validate };
