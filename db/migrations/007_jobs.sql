-- +goose Up

CREATE TABLE job_queue (
    id           BIGSERIAL PRIMARY KEY,
    job_type     VARCHAR(100) NOT NULL,
    payload      JSONB NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'processing', 'done', 'failed')),
    attempts     INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    run_after    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_jobs_pending
    ON job_queue(run_after)
    WHERE status = 'pending';

-- +goose Down

DROP INDEX IF EXISTS idx_jobs_pending;
DROP TABLE IF EXISTS job_queue;
