;; Facility Verification Contract
;; Validates production sites and issues verification tokens

(define-data-var admin principal tx-sender)

;; Data map to store verified facilities
(define-map verified-facilities
  principal ;; facility owner
  {
    facility-id: (string-utf8 36),
    name: (string-utf8 100),
    location: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to register a facility
(define-public (register-facility (facility-id (string-utf8 36)) (name (string-utf8 100)) (location (string-utf8 100)))
  (let ((caller tx-sender))
    (if (map-insert verified-facilities
                    caller
                    {
                      facility-id: facility-id,
                      name: name,
                      location: location,
                      verified: false,
                      verification-date: u0
                    })
        (ok true)
        (err u1) ;; Facility already registered
    )
  )
)

;; Admin function to verify a facility
(define-public (verify-facility (facility-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (match (map-get? verified-facilities facility-owner)
      facility (begin
        (map-set verified-facilities
                facility-owner
                (merge facility {
                  verified: true,
                  verification-date: block-height
                }))
        (ok true)
      )
      (err u404) ;; Facility not found
    )
  )
)

;; Read-only function to check if a facility is verified
(define-read-only (is-facility-verified (facility-owner principal))
  (match (map-get? verified-facilities facility-owner)
    facility (get verified facility)
    false
  )
)

;; Read-only function to get facility details
(define-read-only (get-facility-details (facility-owner principal))
  (map-get? verified-facilities facility-owner)
)

;; Admin function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
